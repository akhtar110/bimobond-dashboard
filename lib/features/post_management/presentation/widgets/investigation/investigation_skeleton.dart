import 'package:flutter/material.dart';

import 'investigation_theme.dart';

class InvestigationSkeleton extends StatelessWidget {
  const InvestigationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= InvestigationTheme.desktop;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Bone(scheme: scheme, height: 20, width: 280),
              const SizedBox(height: InvestigationTheme.s8),
              _Bone(scheme: scheme, height: 14, width: 420),
              const SizedBox(height: InvestigationTheme.s24),
              Expanded(
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 28,
                            child: _Bone(
                              scheme: scheme,
                              height: 420,
                              radius: InvestigationTheme.radius,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 40,
                            child: Column(
                              children: [
                                _Bone(scheme: scheme, height: 120, radius: InvestigationTheme.radius),
                                const SizedBox(height: 12),
                                _Bone(scheme: scheme, height: 240, radius: InvestigationTheme.radius),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 32,
                            child: Column(
                              children: [
                                _Bone(scheme: scheme, height: 180, radius: InvestigationTheme.radius),
                                const SizedBox(height: 12),
                                _Bone(scheme: scheme, height: 220, radius: InvestigationTheme.radius),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _Bone(
                            scheme: scheme,
                            height: 320,
                            radius: InvestigationTheme.radius,
                          ),
                          const SizedBox(height: 12),
                          _Bone(scheme: scheme, height: 200, radius: InvestigationTheme.radius),
                          const SizedBox(height: 12),
                          _Bone(scheme: scheme, height: 280, radius: InvestigationTheme.radius),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _Bone(scheme: scheme, height: 180, radius: InvestigationTheme.radius),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.scheme,
    required this.height,
    this.width,
    this.radius = 8,
  });

  final ColorScheme scheme;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
