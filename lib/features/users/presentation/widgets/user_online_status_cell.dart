import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';

/// Shows a colored online/offline dot + "Last Seen" text.
/// The text refreshes every 60 seconds (so "2m ago" ticks up correctly).
/// Hovering over the "Last Seen" text shows an exact timestamp tooltip.
class UserOnlineStatusCell extends StatefulWidget {
  const UserOnlineStatusCell({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserOnlineStatusCell> createState() => _UserOnlineStatusCellState();
}

class _UserOnlineStatusCellState extends State<UserOnlineStatusCell> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 60s so relative timestamps stay accurate.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _relativeLastSeen() {
    final lastSeen = widget.user.lastSeen;
    if (lastSeen == null) return '—';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) {
      return 'Yesterday, ${DateFormat('h:mm a').format(lastSeen.toLocal())}';
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE, h:mm a').format(lastSeen.toLocal());
    }
    return DateFormat('MMM d, yyyy').format(lastSeen.toLocal());
  }

  String _exactTimestamp() {
    final lastSeen = widget.user.lastSeen;
    if (lastSeen == null) return 'Never seen';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSeen.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isOnline = widget.user.isOnline;
    final dotColor = isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);
    final labelText = isOnline
        ? l10n.tOr('online', 'Online')
        : l10n.tOr('offline', 'Offline');
    final lastSeenText = _relativeLastSeen();
    final exactTime = _exactTimestamp();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status row: dot + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(isOnline: isOnline, color: dotColor),
            const SizedBox(width: 5),
            Text(
              labelText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Last Seen with tooltip for exact timestamp
        Tooltip(
          message: '${l10n.tOr("exactActivity", "Last activity")}: $exactTime',
          child: Text(
            lastSeenText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated pulsing dot for online, static grey dot for offline.
class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.isOnline, required this.color});

  final bool isOnline;
  final Color color;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isOnline) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.isOnline && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isOnline && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pulse.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _pulse.value * 0.5),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge showing ONLY Last Seen (without Online/Offline status dot or text).
class UserLastSeenBadge extends StatefulWidget {
  const UserLastSeenBadge({super.key, required this.user, this.compact = false});

  final UserEntity user;
  final bool compact;

  @override
  State<UserLastSeenBadge> createState() => _UserLastSeenBadgeState();
}

class _UserLastSeenBadgeState extends State<UserLastSeenBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _relativeLastSeen(BuildContext context) {
    final l10n = context.l10n;
    final lastSeen = widget.user.lastSeen;
    if (lastSeen == null) return l10n.tOr('neverSeen', 'Never');
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return l10n.tOr('justNow', 'Just now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) {
      return 'Yesterday, ${DateFormat('h:mm a').format(lastSeen.toLocal())}';
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE, h:mm a').format(lastSeen.toLocal());
    }
    return DateFormat('MMM d, yyyy').format(lastSeen.toLocal());
  }

  String _exactTimestamp() {
    final lastSeen = widget.user.lastSeen;
    if (lastSeen == null) return 'Never seen';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSeen.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lastSeenText = _relativeLastSeen(context);
    final exactTime = _exactTimestamp();

    return Tooltip(
      message: '${l10n.tOr("exactActivity", "Last activity")}: $exactTime',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10,
          vertical: widget.compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: widget.compact ? 12 : 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              '${l10n.tOr("lastSeen", "Last Seen")}: $lastSeenText',
              style: TextStyle(
                fontSize: widget.compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

