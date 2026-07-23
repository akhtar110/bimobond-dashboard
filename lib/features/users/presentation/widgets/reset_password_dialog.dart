import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/validation/password_validator.dart';
import '../../../../core/widgets/password_requirements_widget.dart';
import '../../../../injection_container.dart' as di;
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/users_bloc.dart';

class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({
    super.key,
    required this.userId,
    required this.scaffoldMessenger,
    this.displayName,
  });

  final String userId;
  final String? displayName;
  final ScaffoldMessengerState scaffoldMessenger;

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    String? displayName,
    UsersBloc? usersBloc,
  }) {
    if (!PermissionManager.hasPermission(
      context,
      RbacPermissionKeys.resetUserPassword,
    )) {
      return Future.value(null);
    }

    final ownsBloc = usersBloc == null;
    final bloc = usersBloc ?? di.sl<UsersBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = context.l10n.t('passwordUpdatedSuccessfully');

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: ResetPasswordDialog(
          userId: userId,
          displayName: displayName,
          scaffoldMessenger: messenger,
        ),
      ),
    ).then((result) {
      if (result == true) {
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(successMessage),
          ),
        );
      }
      return result;
    }).whenComplete(() {
      if (ownsBloc) {
        bloc.close();
      }
    });
  }

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _confirmTouched = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _newPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _clearFields() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _confirmTouched = false;
    _serverError = null;
  }

  bool _isLoading(UsersState state) => state is ResetUserPasswordLoading;

  bool _canSubmit(UsersState state) {
    if (_isLoading(state)) return false;

    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    return PasswordValidator.isValid(password) && password == confirm;
  }

  void _submit() {
    final bloc = context.read<UsersBloc>();
    if (!_canSubmit(bloc.state)) return;

    setState(() => _serverError = null);

    bloc.add(
      ResetUserPasswordEvent(
        userId: widget.userId,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 480;
    final dialogWidth = math.min(440.0, size.width - (isCompact ? 24 : 48));
    final contentPadding = isCompact ? 16.0 : 24.0;

    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final showMismatchWarning =
        _confirmTouched && confirm.isNotEmpty && password != confirm;
    final confirmMatches = confirm.isNotEmpty && password == confirm;

    return BlocConsumer<UsersBloc, UsersState>(
      listenWhen: (previous, current) =>
          current is ResetUserPasswordSuccess ||
          current is ResetUserPasswordFailure,
      listener: (context, state) {
        if (state is ResetUserPasswordSuccess) {
          _clearFields();
          Navigator.of(context).pop(true);
          return;
        }

        if (state is ResetUserPasswordFailure) {
          setState(() => _serverError = state.message);
          widget.scaffoldMessenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.errorContainer,
              content: Text(
                state.message.trim().isNotEmpty
                    ? state.message
                    : l10n.t('failedToResetPassword'),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is ResetUserPasswordLoading ||
          previous is ResetUserPasswordLoading ||
          current is! ResetUserPasswordSuccess &&
              current is! ResetUserPasswordFailure,
      builder: (context, blocState) {
        final isLoading = _isLoading(blocState);
        final canSubmit = _canSubmit(blocState);

        return Dialog(
          backgroundColor: scheme.surface,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: scheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('resetPassword'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (widget.displayName != null &&
                                widget.displayName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.displayName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                _clearFields();
                                Navigator.of(context).pop(false);
                              },
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 16 : 22),

                  // Fields
                  _PasswordField(
                    controller: _newPasswordController,
                    label: l10n.t('newPassword'),
                    obscureText: _obscureNewPassword,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    isValid: password.isNotEmpty &&
                        PasswordValidator.isValid(password),
                    onToggleVisibility: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                    onChanged: (_) => setState(() => _serverError = null),
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: l10n.t('confirmPassword'),
                    obscureText: _obscureConfirmPassword,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    isValid: confirmMatches,
                    hasError: showMismatchWarning,
                    onToggleVisibility: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    onChanged: (_) {
                      _confirmTouched = true;
                      setState(() => _serverError = null);
                    },
                  ),
                  if (showMismatchWarning) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.t('passwordsDoNotMatch'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: isCompact ? 14 : 18),

                  // Password rules (below both fields)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('passwordRulesTitle'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        PasswordRequirementsWidget(password: password),
                      ],
                    ),
                  ),

                  // Server error
                  if (_serverError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: scheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _serverError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onErrorContainer,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isCompact ? 18 : 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _clearFields();
                                  Navigator.of(context).pop(false);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                            side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.t('cancel'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: isCompact ? 1 : 2,
                        child: FilledButton(
                          onPressed: canSubmit ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            disabledBackgroundColor:
                                scheme.outline.withValues(alpha: 0.2),
                            disabledForegroundColor:
                                scheme.onSurface.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  l10n.t('resetPassword'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.isValid = false,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final bool isValid;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final borderColor = hasError
        ? scheme.error
        : isValid
            ? scheme.primary.withValues(alpha: 0.6)
            : scheme.outline.withValues(alpha: 0.5);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      autofillHints: autofillHints,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(PasswordValidator.maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? scheme.error : scheme.primary,
            width: 1.5,
          ),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isValid && !hasError)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: scheme.primary,
              ),
            IconButton(
              tooltip:
                  obscureText ? l10n.t('showPassword') : l10n.t('hidePassword'),
              onPressed: enabled ? onToggleVisibility : null,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      onChanged: onChanged,
    );
  }
}
