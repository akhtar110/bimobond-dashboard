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
  });

  final UserDeviceEntity device;
  final bool isDark;

  @override
  State<UserDeviceCard> createState() => _UserDeviceCardState();
}

class _UserDeviceCardState extends State<UserDeviceCard> {
  bool _hovered = false;

  Color _typeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('ios')) return Colors.grey.shade800;
    if (t.contains('android')) return Colors.green.shade700;
    if (t.contains('web')) return Colors.blue.shade700;
    return Colors.purple.shade700;
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
    final l10n = context.l10n;
    final device = widget.device;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final typeColor = _typeColor(device.deviceType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
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
                isDark: widget.isDark,
              ),
              _InfoRow(
                label: l10n.t('appVersion'),
                value: device.appVersion ?? l10n.t('notAvailable'),
                isDark: widget.isDark,
              ),
              _InfoRow(
                label: l10n.t('lastActiveIp'),
                value: device.lastActiveIp ?? l10n.t('notAvailable'),
                isDark: widget.isDark,
              ),
              _InfoRow(
                label: l10n.t('lastActiveAt'),
                value: device.lastActiveAt != null
                    ? dateFormat.format(device.lastActiveAt!)
                    : l10n.t('notAvailable'),
                isDark: widget.isDark,
              ),
              _InfoRow(
                label: l10n.t('registeredAt'),
                value: dateFormat.format(device.createdAt),
                isDark: widget.isDark,
              ),
              if (device.fcmToken != null && device.fcmToken!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.t('fcmToken'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.fcmToken!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
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
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

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
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
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
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
