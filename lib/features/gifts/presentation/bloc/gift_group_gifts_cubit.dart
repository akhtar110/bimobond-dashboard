import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';

class GiftGroupGiftsState extends Equatable {
  const GiftGroupGiftsState({
    this.loading = true,
    this.error,
    this.available = const [],
    this.orderedIds = const [],
    this.searchQuery = '',
  });

  final bool loading;
  final String? error;
  final List<GiftEntity> available;
  final List<String> orderedIds;
  final String searchQuery;

  List<GiftEntity> get filteredAvailable {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return available;
    return available
        .where((gift) => gift.name.toLowerCase().contains(q))
        .toList();
  }

  List<GiftGroupMembershipItem> get membershipItems => [
        for (var i = 0; i < orderedIds.length; i++)
          GiftGroupMembershipItem(giftId: orderedIds[i], sortOrder: i),
      ];

  GiftGroupGiftsState copyWith({
    bool? loading,
    String? error,
    List<GiftEntity>? available,
    List<String>? orderedIds,
    String? searchQuery,
    bool clearError = false,
  }) {
    return GiftGroupGiftsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      available: available ?? this.available,
      orderedIds: orderedIds ?? this.orderedIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        available,
        orderedIds,
        searchQuery,
      ];
}

/// Dialog-local state for assigning gifts to a category/group.
class GiftGroupGiftsCubit extends Cubit<GiftGroupGiftsState> {
  GiftGroupGiftsCubit({
    required GetAdminGifts getAdminGifts,
    required List<GiftGroupMemberEntity> initialMembers,
  })  : _getAdminGifts = getAdminGifts,
        super(
          GiftGroupGiftsState(
            orderedIds: _initialOrderedIds(initialMembers),
          ),
        );

  final GetAdminGifts _getAdminGifts;

  static List<String> _initialOrderedIds(
    List<GiftGroupMemberEntity> initialMembers,
  ) {
    final sorted = [...initialMembers]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.map((member) => member.gift.id).toList();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final gifts = await _getAdminGifts();
      emit(
        state.copyWith(
          available: List<GiftEntity>.unmodifiable(gifts),
          loading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    emit(state.copyWith(searchQuery: query));
  }

  void toggleGift(String giftId) {
    final next = [...state.orderedIds];
    if (next.contains(giftId)) {
      next.remove(giftId);
    } else {
      next.add(giftId);
    }
    emit(state.copyWith(orderedIds: next));
  }

  void selectAllFiltered() {
    final next = [...state.orderedIds];
    for (final gift in state.filteredAvailable) {
      if (!next.contains(gift.id)) {
        next.add(gift.id);
      }
    }
    if (next.length == state.orderedIds.length &&
        next.every(state.orderedIds.contains)) {
      return;
    }
    emit(state.copyWith(orderedIds: next));
  }

  void clearAll() {
    if (state.orderedIds.isEmpty) return;
    emit(state.copyWith(orderedIds: const []));
  }
}
