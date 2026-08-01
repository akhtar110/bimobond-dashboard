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

  void _copy(BuildContext context, String value, String successMessage) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final device = widget.device;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final typeColor = _typeColor(scheme, device.deviceType);
    final deviceName = device.deviceName?.trim();
    final hasDeviceName = deviceName != null && deviceName.isNotEmpty;
    final macAddress = device.macAddress?.trim();
    final hasMac = macAddress != null && macAddress.isNotEmpty;
    final hasDeviceId = device.deviceId.trim().isNotEmpty;

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
                  if (hasDeviceId)
                    IconButton(
                      tooltip: l10n.tOr('copyDeviceId', 'Copy device ID'),
                      icon: const Icon(Icons.fingerprint_outlined, size: 20),
                      onPressed: () => _copy(
                        context,
                        device.deviceId,
                        l10n.tOr(
                          'deviceIdCopied',
                          'Device ID copied to clipboard',
                        ),
                      ),
                    ),
                  if (device.hasPushToken)
                    IconButton(
                      tooltip: l10n.t('copyFcmToken'),
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () => _copy(
                        context,
                        device.fcmToken!,
                        l10n.t('fcmTokenCopied'),
                      ),
                    ),
                ],
              ),
              if (hasDeviceName) ...[
                const SizedBox(height: 12),
                Text(
                  deviceName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (hasDeviceId)
                _InfoRow(
                  label: l10n.t('deviceId'),
                  value: device.deviceId,
                  scheme: scheme,
                  monospace: true,
                ),
              if (hasMac)
                _InfoRow(
                  label: l10n.tOr('macAddress', 'MAC address'),
                  value: macAddress,
                  scheme: scheme,
                  monospace: true,
                ),
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
              _InfoRow(
                label: l10n.tOr('pushNotifications', 'Push notifications'),
                value: device.hasPushToken
                    ? l10n.tOr(
                        'pushNotificationsActive',
                        'Active (FCM token present)',
                      )
                    : l10n.tOr(
                        'pushNotificationsCleared',
                        'Cleared (no FCM token)',
                      ),
                scheme: scheme,
              ),
              if (device.hasPushToken) ...[
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
    this.monospace = false,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final Widget? trailing;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
