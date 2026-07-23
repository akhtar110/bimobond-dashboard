import 'package:flutter/material.dart';

import '../localization/localization.dart';
import '../validation/password_validator.dart';

enum _RequirementStatus { pending, success, error }

class PasswordRequirementsWidget extends StatelessWidget {
  const PasswordRequirementsWidget({
    super.key,
    required this.password,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementRow(
          label: l10n.t('passwordRuleLength'),
          status: _statusFor(
            password,
            PasswordValidator.hasValidLength(password),
          ),
        ),
        const SizedBox(height: 6),
        _RequirementRow(
          label: l10n.t('passwordRuleLetter'),
          status: _statusFor(password, PasswordValidator.hasLetter(password)),
        ),
        const SizedBox(height: 6),
        _RequirementRow(
          label: l10n.t('passwordRuleNumber'),
          status: _statusFor(password, PasswordValidator.hasNumber(password)),
        ),
        const SizedBox(height: 6),
        _RequirementRow(
          label: l10n.t('passwordRuleSpecial'),
          status: _statusFor(
            password,
            PasswordValidator.hasSpecialCharacter(password),
          ),
        ),
      ],
    );
  }

  _RequirementStatus _statusFor(String value, bool satisfied) {
    if (value.isEmpty) return _RequirementStatus.pending;
    return satisfied ? _RequirementStatus.success : _RequirementStatus.error;
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.status,
  });

  final String label;
  final _RequirementStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final Color iconColor;
    final IconData iconData;

    switch (status) {
      case _RequirementStatus.success:
        iconColor = scheme.primary;
        iconData = Icons.check_circle_rounded;
      case _RequirementStatus.error:
        iconColor = scheme.error;
        iconData = Icons.cancel_rounded;
      case _RequirementStatus.pending:
        iconColor = scheme.outline;
        iconData = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            iconData,
            key: ValueKey(status),
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: status == _RequirementStatus.pending
                  ? scheme.onSurface.withValues(alpha: 0.7)
                  : scheme.onSurface,
              fontWeight: status == _RequirementStatus.success
                  ? FontWeight.w600
                  : FontWeight.w400,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
