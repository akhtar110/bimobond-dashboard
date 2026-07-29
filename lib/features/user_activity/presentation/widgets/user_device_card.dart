import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_device_entity.dart';

class UserDeviceCard extends StatefulWidget {
  const UserDeviceCard({
    super.key,
    required this.device,
    required this.isDark,
    this.onViewLastActiveHistory,
  });

  final UserDeviceEntity device;
  final bool isDark;
  final VoidCallback? onViewLastActiveHistory;

  @override
  State<UserDeviceCard> createState() => _UserDeviceCardState();
}

class _UserDeviceCardState extends State<UserDeviceCard> {
  bool _hovered = false;

  Color _typeColor(ColorScheme scheme, String type) {
    final t = type.toLowerCase();
    if (t.contains('ios')) return scheme.onSurface;
    if (t.contains('android')) return scheme.tertiary;
    if (t.contains('web')) return scheme.primary;
    return scheme.secondary;
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('ios')) return Icons.apple;
    if (t.contains('android')) return Icons.android;
    if (t.contains('web')) return Icons.language;
    return Icons.devices_other;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final device = widget.device;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final typeColor = _typeColor(scheme, device.deviceType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: _hovered ? 0.08 : 0.04),
                blurRadius: _hovered ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _typeIcon(device.deviceType),
                          size: 16,
                          color: typeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device.deviceType,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (device.fcmToken != null && device.fcmToken!.isNotEmpty)
                    IconButton(
                      tooltip: l10n.t('copyFcmToken'),
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: device.fcmToken!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('fcmTokenCopied')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: l10n.t('osVersion'),
                value: device.osVersion ?? l10n.t('notAvailable'),
                scheme: scheme,
              ),
              _InfoRow(
                label: l10n.t('appVersion'),
                value: device.appVersion ?? l10n.t('notAvailable'),
                scheme: scheme,
              ),
              _InfoRow(
                label: l10n.t('lastActiveIp'),
                value: device.lastActiveIp ?? l10n.t('notAvailable'),
                scheme: scheme,
              ),
              _InfoRow(
                label: l10n.t('lastActiveAt'),
                value: device.lastActiveAt != null
                    ? dateFormat.format(device.lastActiveAt!)
                    : l10n.t('notAvailable'),
                scheme: scheme,
                trailing: widget.onViewLastActiveHistory == null
                    ? null
                    : IconButton(
                        tooltip: l10n.tOr(
                          'viewLastActiveHistory',
                          'Last active history',
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        onPressed: widget.onViewLastActiveHistory,
                      ),
              ),
              _InfoRow(
                label: l10n.t('registeredAt'),
                value: dateFormat.format(device.createdAt),
                scheme: scheme,
              ),
              if (device.fcmToken != null && device.fcmToken!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.t('fcmToken'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.fcmToken!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.scheme,
    this.trailing,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
