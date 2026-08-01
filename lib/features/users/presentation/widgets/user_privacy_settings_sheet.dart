import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/user_detail_event.dart';
import '../bloc/user_detail_state.dart';

class UserPrivacySettingsSheet extends StatefulWidget {
  const UserPrivacySettingsSheet({super.key, required this.user});

  final UserEntity user;

  static Future<void> show(BuildContext context, {required UserEntity user}) {
    if (!PermissionManager.canUpdateUsers(context)) {
      return Future.value();
    }

    final detailBloc = context.read<UserDetailBloc>();
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    Widget wrap(Widget child) => BlocProvider.value(
          value: detailBloc,
          child: child,
        );

    if (isCompact) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => wrap(UserPrivacySettingsSheet(user: user)),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: wrap(UserPrivacySettingsSheet(user: user)),
      ),
    );
  }

  @override
  State<UserPrivacySettingsSheet> createState() =>
      _UserPrivacySettingsSheetState();
}

class _UserPrivacySettingsSheetState extends State<UserPrivacySettingsSheet> {
  late bool _isPrivate;
  late bool _allowComments;
  late MessagePermission _messagePermission;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.user.isPrivate;
    _allowComments = widget.user.allowComments;
    _messagePermission = widget.user.messagePermission;
  }

  bool get _hasChanges =>
      _isPrivate != widget.user.isPrivate ||
      _allowComments != widget.user.allowComments ||
      _messagePermission != widget.user.messagePermission;

  void _save() {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    context.read<UserDetailBloc>().add(
          UpdateUserPrivacySettingsEvent(
            isPrivate: _isPrivate != widget.user.isPrivate ? _isPrivate : null,
            allowComments: _allowComments != widget.user.allowComments
                ? _allowComments
                : null,
            messagePermission: _messagePermission != widget.user.messagePermission
                ? _messagePermission
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;
    final maxWidth = math.min(480.0, size.width - 24);
    final contentPadding = isCompact ? 16.0 : 24.0;

    return BlocListener<UserDetailBloc, UserDetailState>(
      listenWhen: (previous, current) {
        if (current is! UserDetailLoaded) return false;
        if (!current.isSavingPrivacy && previous is UserDetailLoaded) {
          return previous.isSavingPrivacy && current.actionFeedback != null;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! UserDetailLoaded) return;
        if (state.actionFeedbackIsError) return;
        Navigator.of(context).pop();
      },
      child: BlocBuilder<UserDetailBloc, UserDetailState>(
        buildWhen: (previous, current) {
          if (current is UserDetailLoaded) {
            return current.isSavingPrivacy !=
                (previous is UserDetailLoaded && previous.isSavingPrivacy);
          }
          return false;
        },
        builder: (context, state) {
          final isSaving =
              state is UserDetailLoaded && state.isSavingPrivacy;

          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      Icons.lock_outline_rounded,
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
                          l10n.t('editPrivacySettings'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
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
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.t('privateAccountToggle'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  l10n.t('privateAccountToggleDescription'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: _isPrivate,
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => _isPrivate = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.t('allowCommentsLabel'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: _allowComments,
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => _allowComments = value),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('whoCanMessageLabel'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<MessagePermission>(
                key: ValueKey(_messagePermission),
                value: _messagePermission,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: MessagePermission.values
                    .map(
                      (permission) => DropdownMenuItem(
                        value: permission,
                        child: Text(
                          l10n.tOr(permission.labelKey, permission.name),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _messagePermission = value);
                      },
              ),
              SizedBox(height: isCompact ? 18 : 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: isCompact ? 1 : 2,
                    child: FilledButton(
                      onPressed:
                          isSaving || !_hasChanges ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(l10n.t('saveChanges')),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (isCompact) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Material(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: content,
                  ),
                ),
              ),
            );
          }

          return Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: size.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}
