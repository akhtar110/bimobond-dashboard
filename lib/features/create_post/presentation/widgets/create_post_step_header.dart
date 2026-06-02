import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class CreatePostStepHeader extends StatelessWidget {
  const CreatePostStepHeader({
    super.key,
    required this.currentStep,
    required this.onStepTap,
  });

  final int currentStep;
  final ValueChanged<int> onStepTap;

  static const _steps = [
    'stepMedia',
    'stepDetails',
    'stepSettings',
    'stepPreview',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_steps.length, (index) {
        final selected = index == currentStep;
        final completed = index < currentStep;
        return InkWell(
          onTap: () => onStepTap(index),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? const Color(0xFF312E81)
                      : const Color(0xFFEEF2FF))
                  : completed
                      ? (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? (isDark
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF818CF8))
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: selected || completed
                      ? const Color(0xFF6366F1)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected || completed
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t(_steps[index]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
