import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/chat_socket_service.dart';
import '../../data/models/chat_models.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/entities/chat_queries.dart';
import '../../domain/usecases/chat_management_usecases.dart';
import '../../../users/domain/entities/user_entity.dart';

part 'chat_management_event.dart';
part 'chat_management_state.dart';

class ChatManagementBloc extends Bloc<ChatManagementEvent, ChatManagementState> {
  ChatManagementBloc({
    required GetAllChats getAllChats,
    required GetChatById getChatById,
    required GetChatMessages getChatMessages,
    required UpdateChat updateChat,
    required DeleteChat deleteChat,
    required DeleteChatMessage deleteChatMessage,
    required BulkChatModeration bulkChatModeration,
    required ChatSocketService socketService,
  })  : _getAllChats = getAllChats,
        _getChatById = getChatById,
        _getChatMessages = getChatMessages,
        _updateChat = updateChat,
        _deleteChat = deleteChat,
        _deleteChatMessage = deleteChatMessage,
        _bulkChatModeration = bulkChatModeration,
        _socketService = socketService,
        super(_initialLoaded()) {
    on<ChatManagementStarted>(_onStarted);
    on<ChatManagementStopped>(_onStopped);
    on<ChatsRefreshed>(_onChatsRefreshed);
    on<ChatsLoadMoreRequested>(_onChatsLoadMore);
    on<ChatsGoToPageRequested>(_onChatsGoToPage);
    on<ChatSelected>(_onChatSelected);
    on<MessagesLoadMoreRequested>(_onMessagesLoadMore);
    on<MessagesGoToPageRequested>(_onMessagesGoToPage);
    on<ChatsSearchChanged>(_onChatsSearchChanged);
    on<ChatsTypeFilterChanged>(_onChatsTypeFilterChanged);
    on<ChatsParticipantFilterChanged>(_onChatsParticipantFilterChanged);
    on<ChatsFiltersReset>(_onChatsFiltersReset);
    on<ChatsDateSortChanged>(_onChatsDateSortChanged);
    on<MessagesSearchChanged>(_onMessagesSearchChanged);
    on<MessagesRefreshed>(_onMessagesRefreshed);
    on<MessagesTypeFilterChanged>(_onMessagesTypeFilterChanged);
    on<MessagesDeletedFilterChanged>(_onMessagesDeletedFilterChanged);
    on<ChatSelectionToggled>(_onChatSelectionToggled);
    on<ChatsSelectAllToggled>(_onChatsSelectAllToggled);
    on<ChatsSelectAllVisible>(_onChatsSelectAllVisible);
    on<ChatSelectionCleared>(_onChatSelectionCleared);
    on<MessageSelectionToggled>(_onMessageSelectionToggled);
    on<MessagesSelectAllToggled>(_onMessagesSelectAllToggled);
    on<MessagesSelectAllVisible>(_onMessagesSelectAllVisible);
    on<MessageSelectionCleared>(_onMessageSelectionCleared);
    on<ChatDeleteRequested>(_onChatDeleteRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested);
    on<ChatsBulkDeleteRequested>(_onChatsBulkDeleteRequested);
    on<MessagesBulkDeleteRequested>(_onMessagesBulkDeleteRequested);
    on<ChatMetadataUpdateRequested>(_onChatMetadataUpdateRequested);
    on<ChatSocketEventReceived>(_onSocketEvent);
    on<ChatFeedbackCleared>(_onFeedbackCleared);
  }

  final GetAllChats _getAllChats;
  final GetChatById _getChatById;
  final GetChatMessages _getChatMessages;
  final UpdateChat _updateChat;
  final DeleteChat _deleteChat;
  final DeleteChatMessage _deleteChatMessage;
  final BulkChatModeration _bulkChatModeration;
  final ChatSocketService _socketService;

  StreamSubscription<ChatSocketEvent>? _socketSub;
  Timer? _chatSearchDebounce;
  Timer? _messageSearchDebounce;

  ChatListQuery _listQuery = const ChatListQuery();
  UserEntity? _filterUser;
  ChatDateSort _dateSort = ChatDateSort.newest;
  ChatMessagesQuery _messagesQuery = const ChatMessagesQuery();
  List<ChatEntity> _chats = [];
  PaginationMeta? _chatsMeta;
  ChatEntity? _selectedChat;
  List<ChatMessageEntity> _messages = [];
  PaginationMeta? _messagesMeta;
  Set<String> _selectedChatIds = {};
  Set<String> _selectedMessageIds = {};
  String? _typingUserId;
  bool _isLoadingChats = false;
  bool _isLoadingMoreChats = false;
  bool _isLoadingMessages = false;
  bool _isLoadingMoreMessages = false;
  bool _isSubmitting = false;
  String? _successMessage;
  String? _failureMessage;
  String? _joinedChatId;
  int _listFilterRevision = 0;
  int _messagesFilterRevision = 0;
  int _chatLoadGeneration = 0;
  int _messagesRequestId = 0;
  bool _socketInitialized = false;

  static ChatManagementLoaded _initialLoaded() {
    return const ChatManagementLoaded(
      chats: [],
      listQuery: ChatListQuery(),
      messages: [],
      messagesQuery: ChatMessagesQuery(),
      selectedChatIds: {},
      selectedMessageIds: {},
      isLoadingChats: false,
      isLoadingMoreChats: false,
      isLoadingMessages: false,
      isLoadingMoreMessages: false,
      isSubmitting: false,
      isSocketConnected: false,
      analytics: ChatMessageAnalytics(),
    );
  }

  Future<void> _onStarted(
    ChatManagementStarted event,
    Emitter<ChatManagementState> emit,
  ) async {
    _chatSearchDebounce?.cancel();
    _messageSearchDebounce?.cancel();

    // Reset all per-session state.
    _filterUser = null;
    _listQuery = const ChatListQuery();
    _dateSort = ChatDateSort.newest;
    _selectedChatIds = {};
    _selectedMessageIds = {};
    _chats = [];
    _chatsMeta = null;
    _selectedChat = null;
    _messages = [];
    _messagesMeta = null;
    _failureMessage = null;
    _typingUserId = null;
    _isLoadingChats = true;
    _isLoadingMoreChats = false;
    _emitLoaded(emit);

    try {
      if (!_socketInitialized) {
        _socketService.connect();
        _socketSub ??= _socketService.events.listen(
          (e) => add(ChatSocketEventReceived(e)),
        );
        _socketInitialized = true;
      }
    } catch (_) {
      // Socket must never block the initial chat list fetch.
    }

    await _bootstrapChatList(emit);
  }

  /// First screen open often races Firebase token readiness; retry before showing empty.
  Future<void> _bootstrapChatList(Emitter<ChatManagementState> emit) async {
    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await _reloadChats(emit);
      if (_chats.isNotEmpty || _failureMessage != null) {
        return;
      }
      if (attempt < maxAttempts - 1) {
        await _waitForAuthReady(forceRefresh: true);
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
  }

  Future<void> _onStopped(
    ChatManagementStopped event,
    Emitter<ChatManagementState> emit,
  ) async {
    _chatSearchDebounce?.cancel();
    _messageSearchDebounce?.cancel();
  }

  Future<void> _fetchChats(
    Emitter<ChatManagementState> emit, {
    required bool refresh,
    required int generation,
    bool loadMore = false,
  }) async {
    if (generation != _chatLoadGeneration) return;

    if (loadMore) {
      if (_isLoadingMoreChats) return;
      if (_chatsMeta == null || !_chatsMeta!.hasNextPage) return;
      _isLoadingMoreChats = true;
    } else if (refresh) {
      _listQuery = _listQuery.copyWith(page: 1);
      _chats = [];
      _chatsMeta = null;
      _isLoadingChats = true;
    } else {
      return;
    }

    _emitLoaded(emit);

    try {
      final query = loadMore
          ? _listQuery.copyWith(page: (_chatsMeta?.page ?? 0) + 1)
          : _listQuery;
      final page = await _fetchChatsPage(query);
      if (generation != _chatLoadGeneration) return;
      _listQuery = query;
      _chats = loadMore ? [..._chats, ...page.chats] : page.chats;
      _chatsMeta = page.meta;
      _failureMessage = null;
    } catch (e) {
      if (generation == _chatLoadGeneration) {
        _failureMessage = _errorMessage(e);
      }
    } finally {
      if (generation == _chatLoadGeneration) {
        if (loadMore) {
          _isLoadingMoreChats = false;
        } else {
          _isLoadingChats = false;
        }
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _fetchSelectedChat(
    Emitter<ChatManagementState> emit, {
    required String chatId,
    bool refreshMessages = true,
  }) async {
    try {
      _selectedChat = await _getChatById(chatId);
      if (_joinedChatId != null && _joinedChatId != chatId) {
        _socketService.leaveChat(_joinedChatId!);
      }
      _joinedChatId = chatId;
      _socketService.joinChat(chatId);
      if (refreshMessages) {
        await _fetchMessages(emit, chatId: chatId, refresh: true);
      }
    } catch (e) {
      _failureMessage = _errorMessage(e);
      _emitLoaded(emit);
    }
  }

  Future<void> _fetchMessages(
    Emitter<ChatManagementState> emit, {
    required String chatId,
    required bool refresh,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (_isLoadingMoreMessages) return;
      if (_messagesMeta == null || !_messagesMeta!.hasNextPage) return;
      _isLoadingMoreMessages = true;
    } else {
      if (_isLoadingMessages && !refresh) return;
      _isLoadingMessages = true;
      if (refresh) {
        _messagesQuery = _messagesQuery.copyWith(page: 1);
        _messages = [];
        _messagesMeta = null;
      }
    }
    final requestId = ++_messagesRequestId;
    _emitLoaded(emit);

    try {
      final query = loadMore
          ? _messagesQuery.copyWith(page: (_messagesMeta?.page ?? 0) + 1)
          : _messagesQuery;
      final page = await _getChatMessages(chatId, query);
      if (requestId != _messagesRequestId) return;
      _messagesQuery = query;
      _messages = loadMore ? [..._messages, ...page.messages] : page.messages;
      _messagesMeta = page.meta;
      _failureMessage = null;
    } catch (e) {
      if (requestId == _messagesRequestId) {
        _failureMessage = _errorMessage(e);
      }
    } finally {
      if (requestId == _messagesRequestId) {
        _isLoadingMessages = false;
        _isLoadingMoreMessages = false;
        _emitLoaded(emit);
      }
    }
  }

  void _sortChatsInPlace() {
    _chats.sort((a, b) {
      final cmp = a.updatedAt.compareTo(b.updatedAt);
      return _dateSort == ChatDateSort.newest ? -cmp : cmp;
    });
  }

  /// Messaging-app order: oldest → newest.
  void _sortMessagesInPlace() {
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void _emitLoaded(Emitter<ChatManagementState> emit) {
    if (emit.isDone) return;
    _sortChatsInPlace();
    _sortMessagesInPlace();
    emit(ChatManagementLoaded(
      chats: List.unmodifiable(_chats),
      chatsMeta: _chatsMeta,
      listQuery: _listQuery,
      filterUser: _filterUser,
      dateSort: _dateSort,
      selectedChat: _selectedChat,
      messages: List.unmodifiable(_messages),
      messagesMeta: _messagesMeta,
      messagesQuery: _messagesQuery,
      selectedChatIds: Set.unmodifiable(_selectedChatIds),
      selectedMessageIds: Set.unmodifiable(_selectedMessageIds),
      isLoadingChats: _isLoadingChats,
      isLoadingMoreChats: _isLoadingMoreChats,
      isLoadingMessages: _isLoadingMessages,
      isLoadingMoreMessages: _isLoadingMoreMessages,
      isSubmitting: _isSubmitting,
      isSocketConnected: _socketService.isConnected,
      typingUserId: _typingUserId,
      successMessage: _successMessage,
      failureMessage: _failureMessage,
      analytics: ChatMessageAnalytics.fromMessages(_messages),
      listFilterRevision: _listFilterRevision,
      messagesFilterRevision: _messagesFilterRevision,
    ));
    _successMessage = null;
  }

  Future<void> _onChatsRefreshed(
    ChatsRefreshed event,
    Emitter<ChatManagementState> emit,
  ) =>
      _reloadChats(emit);

  Future<void> _reloadChats(Emitter<ChatManagementState> emit) async {
    final generation = ++_chatLoadGeneration;
    _isLoadingChats = true;
    _isLoadingMoreChats = false;
    _emitLoaded(emit);

    try {
      await _waitForAuthReady(forceRefresh: true);
      if (generation != _chatLoadGeneration) return;
      await _fetchChats(emit, refresh: true, generation: generation);
    } finally {
      if (generation == _chatLoadGeneration) {
        _isLoadingChats = false;
        _isLoadingMoreChats = false;
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onChatsLoadMore(
    ChatsLoadMoreRequested event,
    Emitter<ChatManagementState> emit,
  ) =>
      _fetchChats(
        emit,
        refresh: false,
        loadMore: true,
        generation: _chatLoadGeneration,
      );

  Future<void> _onChatsGoToPage(
    ChatsGoToPageRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    final target = event.page < 1 ? 1 : event.page;
    final last = _chatsMeta?.totalPages ?? 1;
    if (target > last && _chatsMeta != null) return;
    if (target == (_chatsMeta?.page ?? _listQuery.page) && _chats.isNotEmpty) {
      return;
    }

    final generation = ++_chatLoadGeneration;
    _listQuery = _listQuery.copyWith(page: target);
    _chats = [];
    _chatsMeta = null;
    _selectedChatIds.clear();
    _isLoadingChats = true;
    _emitLoaded(emit);

    try {
      final page = await _fetchChatsPage(_listQuery);
      if (generation != _chatLoadGeneration) return;
      _chats = page.chats;
      _chatsMeta = page.meta;
      _listQuery = _listQuery.copyWith(page: page.meta.page);
      _failureMessage = null;
    } catch (e) {
      if (generation == _chatLoadGeneration) {
        _failureMessage = _errorMessage(e);
      }
    } finally {
      if (generation == _chatLoadGeneration) {
        _isLoadingChats = false;
        _emitLoaded(emit);
      }
    }
  }

  Future<void> _onChatSelected(
    ChatSelected event,
    Emitter<ChatManagementState> emit,
  ) async {
    if (event.chatId.isEmpty) {
      _selectedChat = null;
      _messages = [];
      _messagesMeta = null;
      _selectedMessageIds.clear();
      if (_joinedChatId != null) {
        _socketService.leaveChat(_joinedChatId!);
        _joinedChatId = null;
      }
      _emitLoaded(emit);
      return;
    }

    _selectedMessageIds.clear();
    _messages = [];
    _messagesMeta = null;
    _messagesQuery = const ChatMessagesQuery();
    _messagesFilterRevision++;
    _messagesRequestId++;
    _emitLoaded(emit);
    await _fetchSelectedChat(emit, chatId: event.chatId);
    _emitLoaded(emit);
  }

  Future<void> _onMessagesLoadMore(
    MessagesLoadMoreRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    final chatId = _selectedChat?.id;
    if (chatId == null) return;
    await _fetchMessages(emit, chatId: chatId, refresh: false, loadMore: true);
  }

  Future<void> _onMessagesGoToPage(
    MessagesGoToPageRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    final chatId = _selectedChat?.id;
    if (chatId == null) return;

    final target = event.page < 1 ? 1 : event.page;
    final last = _messagesMeta?.totalPages ?? 1;
    if (target > last && _messagesMeta != null) return;
    if (target == (_messagesMeta?.page ?? _messagesQuery.page) &&
        _messages.isNotEmpty) {
      return;
    }

    _messagesQuery = _messagesQuery.copyWith(page: target);
    await _fetchMessages(emit, chatId: chatId, refresh: false, loadMore: false);
  }

  Future<void> _onChatsSearchChanged(
    ChatsSearchChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    _chatSearchDebounce?.cancel();
    final trimmed = event.query.trim();
    final currentSearch = _listQuery.search?.trim() ?? '';
    if (trimmed == currentSearch) return;

    _listQuery = trimmed.isEmpty
        ? _listQuery.copyWith(clearSearch: true, page: 1)
        : _listQuery.copyWith(search: trimmed, page: 1);
    _selectedChatIds.clear();
    _emitLoaded(emit);
    _chatSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      add(const ChatsRefreshed());
    });
  }

  Future<ChatListPageEntity> _fetchChatsPage(ChatListQuery query) async {
    if (_usesMergedAllFetch(query)) {
      var page = await _fetchMergedAllChats(query);
      if (page.chats.isEmpty && query.page == 1) {
        await _waitForAuthReady(forceRefresh: true);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final retry = await _fetchMergedAllChats(query);
        if (retry.chats.isNotEmpty) return retry;
      }
      return page;
    }
    return _fetchSingleChatsPage(query);
  }

  bool _usesMergedAllFetch(ChatListQuery query) {
    if (query.typeFilter != ChatTypeFilter.all) return false;
    if (query.search?.trim().isNotEmpty == true) return false;
    if (query.userId?.trim().isNotEmpty == true) return false;
    return true;
  }

  Future<ChatListPageEntity> _fetchSingleChatsPage(ChatListQuery query) async {
    await _waitForAuthReady();
    return _getAllChatsOnce(query);
  }

  Future<ChatListPageEntity> _getAllChatsOnce(ChatListQuery query) async {
    try {
      return await _getAllChats(query);
    } catch (e) {
      final message = _errorMessage(e).toLowerCase();
      final authIssue = message.contains('authorization') ||
          message.contains('unauthorized') ||
          message.contains('401');
      if (authIssue) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await _waitForAuthReady(forceRefresh: true);
        return _getAllChats(query);
      }
      rethrow;
    }
  }

  Future<ChatListPageEntity> _fetchMergedAllChats(ChatListQuery query) async {
    final page = query.page;
    final results = await Future.wait([
      _getAllChatsOnce(
        query.copyWith(typeFilter: ChatTypeFilter.group, page: page),
      ),
      _getAllChatsOnce(
        query.copyWith(typeFilter: ChatTypeFilter.direct, page: page),
      ),
    ]);
    final group = results[0];
    final direct = results[1];

    final seen = <String>{};
    final merged = <ChatEntity>[];
    for (final chat in [...group.chats, ...direct.chats]) {
      if (seen.add(chat.id)) merged.add(chat);
    }
    merged.sort((a, b) {
      final cmp = a.updatedAt.compareTo(b.updatedAt);
      return _dateSort == ChatDateSort.newest ? -cmp : cmp;
    });

    final total = group.meta.total + direct.meta.total;
    final totalPages = group.meta.totalPages > direct.meta.totalPages
        ? group.meta.totalPages
        : direct.meta.totalPages;

    return ChatListPageEntity(
      chats: merged,
      meta: PaginationMeta(
        total: total,
        page: page,
        limit: query.limit,
        totalPages: totalPages > 0 ? totalPages : 1,
      ),
    );
  }

  Future<void> _waitForAuthReady({bool forceRefresh = false}) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .where((candidate) => candidate != null)
              .map((candidate) => candidate!)
              .first
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          user = null;
        }
      }

      if (user != null) {
        try {
          final token = await user.getIdToken(forceRefresh || attempt > 0);
          if (token != null && token.isNotEmpty) return;
        } catch (_) {
          // Retry with a refreshed token on the next attempt.
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
    }
  }

  Future<void> _onChatsTypeFilterChanged(
    ChatsTypeFilterChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    final filterChanged = _listQuery.typeFilter != event.filter;
    _listQuery = _listQuery.copyWith(typeFilter: event.filter, page: 1);
    if (filterChanged) _selectedChatIds.clear();
    _emitLoaded(emit);
    await _reloadChats(emit);
  }

  Future<void> _onChatsParticipantFilterChanged(
    ChatsParticipantFilterChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    final nextUserId = event.user?.id;
    if (_filterUser?.id == nextUserId) return;
    _filterUser = event.user;
    _listQuery = _listQuery.copyWith(
      userId: nextUserId,
      clearUserId: event.user == null,
      page: 1,
    );
    _selectedChatIds.clear();
    _emitLoaded(emit);
    await _reloadChats(emit);
  }

  Future<void> _onChatsFiltersReset(
    ChatsFiltersReset event,
    Emitter<ChatManagementState> emit,
  ) async {
    _chatSearchDebounce?.cancel();
    _filterUser = null;
    _listQuery = const ChatListQuery();
    _dateSort = ChatDateSort.newest;
    _selectedChatIds.clear();
    _listFilterRevision++;
    _emitLoaded(emit);
    await _reloadChats(emit);
  }

  Future<void> _onChatsDateSortChanged(
    ChatsDateSortChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    if (_dateSort == event.sort) return;
    _dateSort = event.sort;
    _emitLoaded(emit);
  }

  Future<void> _onMessagesSearchChanged(
    MessagesSearchChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    final chatId = _selectedChat?.id;
    if (chatId == null) return;
    _messageSearchDebounce?.cancel();
    final trimmed = event.query.trim();
    final currentSearch = _messagesQuery.search?.trim() ?? '';
    if (trimmed == currentSearch) return;

    _messagesQuery = trimmed.isEmpty
        ? _messagesQuery.copyWith(clearSearch: true, page: 1)
        : _messagesQuery.copyWith(search: trimmed, page: 1);
    _selectedMessageIds.clear();
    _emitLoaded(emit);
    _messageSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      add(MessagesRefreshed(chatId));
    });
  }

  Future<void> _onMessagesRefreshed(
    MessagesRefreshed event,
    Emitter<ChatManagementState> emit,
  ) async {
    if (_selectedChat?.id != event.chatId) return;
    await _fetchMessages(emit, chatId: event.chatId, refresh: true);
  }

  Future<void> _onMessagesTypeFilterChanged(
    MessagesTypeFilterChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    final chatId = _selectedChat?.id;
    if (chatId == null) return;
    if (_messagesQuery.typeFilter == event.filter) return;
    _messagesQuery = _messagesQuery.copyWith(typeFilter: event.filter, page: 1);
    _selectedMessageIds.clear();
    _messagesFilterRevision++;
    _emitLoaded(emit);
    await _fetchMessages(emit, chatId: chatId, refresh: true);
  }

  Future<void> _onMessagesDeletedFilterChanged(
    MessagesDeletedFilterChanged event,
    Emitter<ChatManagementState> emit,
  ) async {
    final chatId = _selectedChat?.id;
    if (chatId == null) return;
    if (_messagesQuery.deletedFilter == event.filter) return;
    _messagesQuery =
        _messagesQuery.copyWith(deletedFilter: event.filter, page: 1);
    _selectedMessageIds.clear();
    _messagesFilterRevision++;
    _emitLoaded(emit);
    await _fetchMessages(emit, chatId: chatId, refresh: true);
  }

  void _onChatSelectionToggled(
    ChatSelectionToggled event,
    Emitter<ChatManagementState> emit,
  ) {
    if (_selectedChatIds.contains(event.chatId)) {
      _selectedChatIds.remove(event.chatId);
    } else {
      _selectedChatIds.add(event.chatId);
    }
    _emitLoaded(emit);
  }

  void _onChatsSelectAllToggled(
    ChatsSelectAllToggled event,
    Emitter<ChatManagementState> emit,
  ) {
    final allSelected =
        _chats.isNotEmpty && _chats.every((c) => _selectedChatIds.contains(c.id));
    if (allSelected) {
      _selectedChatIds.clear();
    } else {
      _selectedChatIds = _chats.map((c) => c.id).toSet();
    }
    _emitLoaded(emit);
  }

  void _onChatsSelectAllVisible(
    ChatsSelectAllVisible event,
    Emitter<ChatManagementState> emit,
  ) {
    if (_chats.isEmpty) return;
    _selectedChatIds = _chats.map((c) => c.id).toSet();
    _emitLoaded(emit);
  }

  void _onChatSelectionCleared(
    ChatSelectionCleared event,
    Emitter<ChatManagementState> emit,
  ) {
    _selectedChatIds.clear();
    _emitLoaded(emit);
  }

  void _onMessageSelectionToggled(
    MessageSelectionToggled event,
    Emitter<ChatManagementState> emit,
  ) {
    if (_selectedMessageIds.contains(event.messageId)) {
      _selectedMessageIds.remove(event.messageId);
    } else {
      _selectedMessageIds.add(event.messageId);
    }
    _emitLoaded(emit);
  }

  void _onMessagesSelectAllToggled(
    MessagesSelectAllToggled event,
    Emitter<ChatManagementState> emit,
  ) {
    final allSelected = _messages.isNotEmpty &&
        _messages.every((m) => _selectedMessageIds.contains(m.id));
    if (allSelected) {
      _selectedMessageIds.clear();
    } else {
      _selectedMessageIds = _messages.map((m) => m.id).toSet();
    }
    _emitLoaded(emit);
  }

  void _onMessagesSelectAllVisible(
    MessagesSelectAllVisible event,
    Emitter<ChatManagementState> emit,
  ) {
    if (_messages.isEmpty) return;
    _selectedMessageIds = _messages.map((m) => m.id).toSet();
    _emitLoaded(emit);
  }

  void _onMessageSelectionCleared(
    MessageSelectionCleared event,
    Emitter<ChatManagementState> emit,
  ) {
    _selectedMessageIds.clear();
    _emitLoaded(emit);
  }

  Future<void> _onChatDeleteRequested(
    ChatDeleteRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    _isSubmitting = true;
    _emitLoaded(emit);
    try {
      await _deleteChat(event.chatId);
      _chats.removeWhere((c) => c.id == event.chatId);
      _selectedChatIds.remove(event.chatId);
      if (_selectedChat?.id == event.chatId) {
        _selectedChat = null;
        _messages = [];
        _messagesMeta = null;
      }
      _successMessage = 'chatDeletedSuccess';
    } catch (e) {
      _failureMessage = _errorMessage(e);
    } finally {
      _isSubmitting = false;
      _emitLoaded(emit);
    }
  }

  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    _isSubmitting = true;
    _emitLoaded(emit);
    try {
      await _deleteChatMessage(event.messageId);
      _messages = _messages
          .map(
            (m) => m.id == event.messageId
                ? ChatMessageModel(
                    id: m.id,
                    chatId: m.chatId,
                    senderId: m.senderId,
                    type: m.type,
                    content: 'This message was deleted',
                    isDeleted: true,
                    createdAt: m.createdAt,
                    updatedAt: DateTime.now(),
                    sender: m.sender,
                    reactions: m.reactions,
                    readReceipts: m.readReceipts,
                    replyTo: m.replyTo,
                  )
                : m,
          )
          .toList();
      _selectedMessageIds.remove(event.messageId);
      _successMessage = 'messageDeletedSuccess';
    } catch (e) {
      _failureMessage = _errorMessage(e);
    } finally {
      _isSubmitting = false;
      _emitLoaded(emit);
    }
  }

  Future<void> _onChatsBulkDeleteRequested(
    ChatsBulkDeleteRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    final ids = _selectedChatIds.toList();
    if (ids.isEmpty) return;
    _isSubmitting = true;
    _emitLoaded(emit);
    try {
      final result = await _bulkChatModeration(
        action: ChatBulkAction.deleteChats,
        chatIds: ids,
      );
      _chats.removeWhere((c) => ids.contains(c.id));
      _selectedChatIds.clear();
      if (_selectedChat != null && ids.contains(_selectedChat!.id)) {
        _selectedChat = null;
        _messages = [];
      }
      _successMessage =
          'bulkChatsDeleted:${result.successCount}:${result.notFoundCount}';
    } catch (e) {
      _failureMessage = _errorMessage(e);
    } finally {
      _isSubmitting = false;
      _emitLoaded(emit);
    }
  }

  Future<void> _onMessagesBulkDeleteRequested(
    MessagesBulkDeleteRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    final ids = _selectedMessageIds.toList();
    if (ids.isEmpty) return;
    _isSubmitting = true;
    _emitLoaded(emit);
    try {
      final result = await _bulkChatModeration(
        action: ChatBulkAction.deleteMessages,
        messageIds: ids,
      );
      for (final id in ids) {
        final idx = _messages.indexWhere((m) => m.id == id);
        if (idx >= 0) {
          final m = _messages[idx];
          _messages[idx] = ChatMessageModel(
            id: m.id,
            chatId: m.chatId,
            senderId: m.senderId,
            type: m.type,
            content: 'This message was deleted',
            isDeleted: true,
            createdAt: m.createdAt,
            updatedAt: DateTime.now(),
            sender: m.sender,
          );
        }
      }
      _selectedMessageIds.clear();
      _successMessage =
          'bulkMessagesDeleted:${result.successCount}:${result.notFoundCount}';
    } catch (e) {
      _failureMessage = _errorMessage(e);
    } finally {
      _isSubmitting = false;
      _emitLoaded(emit);
    }
  }

  Future<void> _onChatMetadataUpdateRequested(
    ChatMetadataUpdateRequested event,
    Emitter<ChatManagementState> emit,
  ) async {
    _isSubmitting = true;
    _emitLoaded(emit);
    try {
      final updated = await _updateChat(
        event.chatId,
        UpdateChatData(name: event.name, avatarUrl: event.avatarUrl),
      );
      _selectedChat = updated;
      _chats = _chats
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      _successMessage = 'chatUpdatedSuccess';
    } catch (e) {
      _failureMessage = _errorMessage(e);
    } finally {
      _isSubmitting = false;
      _emitLoaded(emit);
    }
  }

  void _onSocketEvent(
    ChatSocketEventReceived event,
    Emitter<ChatManagementState> emit,
  ) {
    final socketEvent = event.event;
    switch (socketEvent.type) {
      case ChatSocketEventType.connected:
        _emitLoaded(emit);
      case ChatSocketEventType.newMessage:
        final message = socketEvent.message;
        if (message == null) return;
        if (_selectedChat?.id == message.chatId) {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages = [..._messages, message];
          }
        }
        final chatIdx = _chats.indexWhere((c) => c.id == message.chatId);
        if (chatIdx >= 0) {
          final chat = _chats.removeAt(chatIdx);
          _chats.insert(
            0,
            ChatModel(
              id: chat.id,
              isGroup: chat.isGroup,
              name: chat.name,
              avatarUrl: chat.avatarUrl,
              createdAt: chat.createdAt,
              updatedAt: message.createdAt,
              participants: chat.participants,
              messageCount: chat.messageCount + 1,
              participantCount: chat.participantCount,
              lastMessage: ChatPreviewMessageModel(
                id: message.id,
                chatId: message.chatId,
                senderId: message.senderId,
                type: message.type,
                content: message.content,
                isDeleted: message.isDeleted,
                createdAt: message.createdAt,
                sender: message.sender,
              ),
            ),
          );
        }
        _emitLoaded(emit);
      case ChatSocketEventType.messageDeleted:
        final messageId = socketEvent.messageId;
        if (messageId == null) return;
        _messages = _messages
            .map(
              (m) => m.id == messageId
                  ? ChatMessageModel(
                      id: m.id,
                      chatId: m.chatId,
                      senderId: m.senderId,
                      type: m.type,
                      content: 'This message was deleted',
                      isDeleted: true,
                      createdAt: m.createdAt,
                      updatedAt: DateTime.now(),
                      sender: m.sender,
                    )
                  : m,
            )
            .toList();
        _emitLoaded(emit);
      case ChatSocketEventType.userTyping:
        _typingUserId =
            socketEvent.isTyping == true ? socketEvent.userId : null;
        _emitLoaded(emit);
      case ChatSocketEventType.messageRead:
      case ChatSocketEventType.messageReacted:
        break;
    }
  }

  void _onFeedbackCleared(
    ChatFeedbackCleared event,
    Emitter<ChatManagementState> emit,
  ) {
    _successMessage = null;
    _failureMessage = null;
    _emitLoaded(emit);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.map((e) => e.toString()).join(', ');
        }
      }
      return error.message ?? error.toString();
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Future<void> close() {
    _chatSearchDebounce?.cancel();
    _messageSearchDebounce?.cancel();
    _socketSub?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
