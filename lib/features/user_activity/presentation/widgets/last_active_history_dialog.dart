import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/api_error_messages.dart';
import '../../../../injection_container.dart';
import '../../../user_history/domain/entities/user_history_entity.dart';
import '../../../user_history/domain/usecases/get_user_history_usecase.dart';

Future<void> showLastActiveHistoryDialog(
  BuildContext context, {
  required String userId,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => LastActiveHistoryDialog(userId: userId),
  );
}

class LastActiveHistoryDialog extends StatefulWidget {
  const LastActiveHistoryDialog({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<LastActiveHistoryDialog> createState() =>
      _LastActiveHistoryDialogState();
}

class _LastActiveHistoryDialogState extends State<LastActiveHistoryDialog> {
  final _getUserHistory = sl<GetUserHistoryUseCase>();
  final _scrollController = ScrollController();

  final List<UserHistoryEntity> _items = [];
  UserHistoryMetaEntity? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(page: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _loading) return;
    final meta = _meta;
    if (meta == null || meta.hasReachedMax) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 120) return;
    _load(page: meta.page + 1, append: true);
  }

  Future<void> _load({required int page, bool append = false}) async {
    if (widget.userId.isEmpty) return;

    setState(() {
      if (append) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final result = await _getUserHistory(
        userId: widget.userId,
        query: UserHistoryQuery(
          page: page,
          limit: 30,
          types: const [UserHistoryTypes.authLogin],
        ),
      );

      if (!mounted) return;
      setState(() {
        if (append) {
          _items.addAll(result.items);
        } else {
          _items
            ..clear()
            ..addAll(result.items);
        }
        _meta = result.meta;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = ApiErrorMessages.from(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width < 560 ? size.width * 0.92 : 480.0;
    final dialogHeight = size.height * 0.62;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      title: Row(
        children: [
          Icon(Icons.history_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.tOr('lastActiveHistory', 'Last Active History'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: _buildBody(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _load(page: 1),
                child: Text(l10n.t('tryAgain')),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          l10n.tOr('noLastActiveHistory', 'No last active history found.'),
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        if (_meta != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n
                    .tOr('lastActiveHistoryCount', '{count} events')
                    .replaceAll('{count}', '${_meta!.total}'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            itemCount: _items.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _LastActiveHistoryTile(item: _items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _LastActiveHistoryTile extends StatelessWidget {
  const _LastActiveHistoryTile({required this.item});

  final UserHistoryEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    final ip = item.dataString('ip') ??
        item.dataString('lastActiveIp') ??
        item.dataString('ipAddress') ??
        item.dataString('clientIp');
    final deviceType = item.dataString('deviceType') ??
        item.dataString('platform') ??
        item.nestedString('device', 'deviceType');
    final deviceId = item.dataString('deviceId') ??
        item.nestedString('device', 'deviceId');
    final osVersion = item.dataString('osVersion') ??
        item.nestedString('device', 'osVersion');
    final appVersion = item.dataString('appVersion') ??
        item.nestedString('device', 'appVersion');
    final userAgent = item.dataString('userAgent');

    final details = <String>[
      if (ip != null) '${l10n.t('lastActiveIp')}: $ip',
      if (deviceType != null)
        '${l10n.tOr('deviceType', 'Device')}: $deviceType',
      if (deviceId != null)
        '${l10n.tOr('deviceId', 'Device ID')}: $deviceId',
      if (osVersion != null) '${l10n.t('osVersion')}: $osVersion',
      if (appVersion != null) '${l10n.t('appVersion')}: $appVersion',
      if (userAgent != null)
        '${l10n.tOr('userAgent', 'User agent')}: $userAgent',
    ];

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.login_rounded,
                size: 16,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tOr('authLoginEvent', 'Login'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(item.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...details.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
