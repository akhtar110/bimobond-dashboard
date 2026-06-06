import 'package:flutter/material.dart';

import 'investigation_theme.dart';

class InvestigationSkeleton extends StatelessWidget {
  const InvestigationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= InvestigationTheme.desktop;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Bone(height: 20, width: 280),
              const SizedBox(height: InvestigationTheme.s8),
              const _Bone(height: 14, width: 420),
              const SizedBox(height: InvestigationTheme.s24),
              Expanded(
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: const [
                                _Bone(height: 320, radius: 18),
                                SizedBox(height: 16),
                                _Bone(height: 200, radius: 18),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: const [
                                _Bone(height: 180, radius: 18),
                                SizedBox(height: 12),
                                _Bone(height: 120, radius: 18),
                                SizedBox(height: 12),
                                _Bone(height: 220, radius: 18),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: const [
                          _Bone(height: 240, radius: 18),
                          SizedBox(height: 12),
                          _Bone(height: 160, radius: 18),
                          SizedBox(height: 12),
                          _Bone(height: 280, radius: 18),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              const _Bone(height: 180, radius: 18),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.height, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: InvestigationTheme.animMs),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
