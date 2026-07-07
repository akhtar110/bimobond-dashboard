import 'package:flutter/material.dart';

import '../../../user_reports/presentation/bloc/user_reports_bloc.dart';
import '../reports_inline_detail.dart';
import '../utils/reports_center_theme.dart';
import 'reports_inline_detail_panel.dart';

/// Trailing-edge slide-in detail panel (overlay, does not push layout).
class ReportsDetailOverlayDrawer extends StatelessWidget {
  const ReportsDetailOverlayDrawer({
    super.key,
    required this.detail,
    required this.onClose,
    this.panelWidth = 520,
    this.userReportsBloc,
  });

  final ReportsInlineDetail detail;
  final VoidCallback onClose;
  final double panelWidth;
  final UserReportsBloc? userReportsBloc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final resolvedWidth = panelWidth.clamp(320, screenWidth).toDouble();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: ReportsCenterTheme.medium,
            curve: ReportsCenterTheme.ease,
            builder: (context, t, child) => GestureDetector(
              onTap: onClose,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.22 * t),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: isRtl ? 0 : null,
          right: isRtl ? null : 0,
          width: resolvedWidth,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: ReportsCenterTheme.medium,
            curve: ReportsCenterTheme.ease,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(
                isRtl ? -resolvedWidth * t : resolvedWidth * t,
                0,
              ),
              child: child,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(
                left: isRtl ? Radius.zero : const Radius.circular(20),
                right: isRtl ? const Radius.circular(20) : Radius.zero,
              ),
              child: DecoratedBox(
                decoration: ReportsCenterTheme.drawerPanel(scheme),
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox.expand(
                    child: ReportsInlineDetailPanel(
                      detail: detail,
                      onClose: onClose,
                      userReportsBloc: userReportsBloc,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
