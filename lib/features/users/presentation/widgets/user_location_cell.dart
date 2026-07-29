import 'package:flutter/material.dart';

import '../../domain/entities/user_entity.dart';
import '../utils/user_location_list_utils.dart';

class UserLocationCell extends StatelessWidget {
  const UserLocationCell({
    super.key,
    required this.user,
    this.compact = false,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final UserEntity user;
  final bool compact;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = userListLocationLabel(user);
    final tooltip = userLocationTooltip(context, user);

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: compact ? 10.5 : 11.5,
      height: 1.25,
      color: label.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
      fontStyle: label.isEmpty ? FontStyle.italic : FontStyle.normal,
    );

    final child = Text(
      label.isEmpty ? '—' : label,
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );

    return Align(
      alignment: alignment,
      child: tooltip == null
          ? child
          : Tooltip(
              message: tooltip,
              preferBelow: true,
              waitDuration: const Duration(milliseconds: 400),
              child: child,
            ),
    );
  }
}
