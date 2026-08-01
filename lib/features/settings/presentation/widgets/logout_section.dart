import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'settings_section.dart';

class LogoutSection extends StatefulWidget {
  const LogoutSection({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<LogoutSection> createState() => _LogoutSectionState();
}

class _LogoutSectionState extends State<LogoutSection> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = scheme.error;
    final dangerBg = scheme.errorContainer;

    return SettingsSection(
      title: l10n.t('session'),
      child: SettingsSurfaceCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically = constraints.maxWidth < 560;

            final info = Text(
              l10n.t('logout'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            );

            final button = MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _hovered
                      ? dangerBg.withValues(alpha: 0.55)
                      : scheme.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: Icon(Icons.logout_rounded, size: 18, color: danger),
                  label: Text(l10n.t('logout')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: BorderSide(
                      color: danger.withValues(alpha: _hovered ? 0.9 : 0.55),
                      width: _hovered ? 1.5 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: button,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}
