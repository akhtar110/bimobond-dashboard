import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_admin_action_type.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_wallet_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/user_detail_event.dart';
import '../bloc/user_detail_state.dart';
import '../utils/user_detail_layout_metrics.dart';
import '../utils/users_export_service.dart';
import '../widgets/user_account_risk_section.dart';
import '../widgets/user_admin_actions/user_admin_actions_section.dart';
import '../widgets/user_detail_activity_tabs.dart';
import '../widgets/user_detail_header.dart';
import '../widgets/user_detail_locked_card.dart';
import '../widgets/user_detail_personal_info.dart';
import '../widgets/user_detail_stats_grid.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  void _showAvatarPreview(UserEntity user) {
    final url = user.avatarUrl?.trim();
    if (url == null || url.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final size = MediaQuery.sizeOf(ctx);
        final maxSide = (size.shortestSide * 0.86).clamp(240.0, 520.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxSide,
                  maxHeight: maxSide,
                ),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      width: maxSide,
                      height: maxSide,
                      placeholder: (_, _) => SizedBox(
                        width: maxSide,
                        height: maxSide,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => SizedBox(
                        width: maxSide,
                        height: maxSide,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return BlocListener<UserDetailBloc, UserDetailState>(
      listenWhen: (previous, current) {
        if (current is! UserDetailLoaded) return false;
        if (current.userDeleted) return true;
        if (current.actionFeedback == null) return false;
        if (previous is! UserDetailLoaded) return true;
        return previous.actionFeedback != current.actionFeedback;
      },
      listener: (context, state) {
        if (state is! UserDetailLoaded) return;

        if (state.userDeleted) {
          final message = l10n.tOr(
            state.actionFeedback ?? 'adminSuccessDeleted',
            'User deleted successfully',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(message),
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        final message = state.actionFeedback;
        if (message == null) return;

        final text = state.actionFeedbackIsError
            ? message
            : l10n.tOr(message, message);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                state.actionFeedbackIsError ? scheme.errorContainer : null,
            content: Text(
              text,
              style: TextStyle(
                color: state.actionFeedbackIsError
                    ? scheme.onErrorContainer
                    : null,
              ),
            ),
          ),
        );
        context.read<UserDetailBloc>().add(ClearUserDetailActionFeedbackEvent());
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: scheme.onSurface,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.t('userDetails'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          centerTitle: false,
          actions: [
            BlocBuilder<UserDetailBloc, UserDetailState>(
              builder: (context, state) {
                final targetUser = state is UserDetailLoaded
                    ? state.userDetail.user
                    : widget.user;
                return UserDetailExportButton(user: targetUser);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<UserDetailBloc, UserDetailState>(
          builder: (context, state) {
            if (state is UserDetailInitial || state is UserDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: scheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.read<UserDetailBloc>().add(
                              LoadUserDetailEvent(widget.user),
                            ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.t('retry')),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is UserDetailLoaded) {
              final user = state.userDetail.user;
              final width = MediaQuery.sizeOf(context).width;
              final metrics = userDetailLayoutMetrics(width);

              return SingleChildScrollView(
                padding: EdgeInsets.all(metrics.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocSelector<UserDetailBloc, UserDetailState,
                        ({
                          UserEntity user,
                          UserAdminActionType? executingAction
                        })?>(
                      selector: (s) {
                        if (s is! UserDetailLoaded) return null;
                        return (
                          user: s.userDetail.user,
                          executingAction: s.executingAction,
                        );
                      },
                      builder: (context, data) {
                        if (data == null) return const SizedBox.shrink();
                        return UserDetailHeader(
                          user: data.user,
                          onAvatarTap: () => _showAvatarPreview(data.user),
                          adminActions: UserAdminActionsSection(
                            user: data.user,
                            executingAction: data.executingAction,
                            isBusy: data.executingAction != null,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    BlocSelector<UserDetailBloc, UserDetailState,
                        ({
                          UserEntity user,
                          UserWalletEntity? wallet,
                          int followerCount,
                          int followingCount,
                        })?>(
                      selector: (s) {
                        if (s is! UserDetailLoaded) return null;
                        final user = s.userDetail.user;
                        return (
                          user: user,
                          wallet: s.userDetail.wallet ?? user.wallet,
                          followerCount: user.followerCount,
                          followingCount: user.followingCount,
                        );
                      },
                      builder: (context, data) {
                        if (data == null) return const SizedBox.shrink();
                        return UserDetailStatsGrid(
                          user: data.user,
                          wallet: data.wallet,
                        );
                      },
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    UserAccountRiskSection(user: user),
                    SizedBox(height: metrics.sectionSpacing),
                    if (user.isProfileLocked) ...[
                      UserDetailLockedCard(user: user),
                      SizedBox(height: metrics.sectionSpacing),
                      UserDetailPersonalInfo(user: user),
                    ] else
                      UserDetailInfoActivitySection(
                        user: user,
                        isDark: isDark,
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class UserDetailExportButton extends StatefulWidget {
  const UserDetailExportButton({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserDetailExportButton> createState() => _UserDetailExportButtonState();
}

class _UserDetailExportButtonState extends State<UserDetailExportButton> {
  bool _isExporting = false;

  Future<void> _handleExport(UsersExportFormat format) async {
    setState(() => _isExporting = true);
    try {
      await UsersExportService.exportSingleUser(
        user: widget.user,
        format: format,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User details for @${widget.user.username} exported successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export user details: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    if (_isExporting) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<UsersExportFormat>(
      tooltip: l10n.tOr('export', 'Export'),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      onSelected: _handleExport,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          height: 32,
          child: Text(
            l10n.tOr('exportUserDetails', 'EXPORT USER DETAILS'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ),
        PopupMenuItem(
          value: UsersExportFormat.excel,
          child: Row(
            children: [
              const Icon(Icons.table_chart_rounded, size: 18, color: Colors.green),
              const SizedBox(width: 10),
              Text(l10n.tOr('exportToExcel', 'Export to Excel (.xlsx)')),
            ],
          ),
        ),
        PopupMenuItem(
          value: UsersExportFormat.csv,
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Text(l10n.tOr('exportToCsv', 'Export to CSV (.csv)')),
            ],
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.tOr('export', 'Export'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
