import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auctions/presentation/utils/auctions_responsive.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/seller_verification_entities.dart';
import '../bloc/seller_verification_bloc.dart';
import '../utils/seller_verification_status_style.dart';
import 'seller_verification_detail_sheet.dart';
import 'seller_verification_reject_dialog.dart';

class SellerVerificationPanel extends StatelessWidget {
  const SellerVerificationPanel({
    super.key,
    required this.screenWidth,
    required this.useDesktopPagination,
    required this.pageHorizontalPadding,
  });

  final double screenWidth;
  final bool useDesktopPagination;
  final double pageHorizontalPadding;

  int _columnsForWidth(double width) {
    if (width > 1200) return 3;
    if (width > 760) return 2;
    return 1;
  }

  double _sideInset(double extent) {
    const maxW = AuctionsLayoutMetrics.maxContentWidth;
    final base = pageHorizontalPadding;
    if (extent > maxW) return ((extent - maxW) / 2) + base;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canReview = PermissionManager.canReviewSellerVerification(context);
    final compact = screenWidth < 700;

    return BlocConsumer<SellerVerificationBloc, SellerVerificationState>(
      listenWhen: (previous, current) =>
          current is SellerVerificationLoaded &&
          current.feedbackMessage != null,
      listener: (context, state) {
        if (state is! SellerVerificationLoaded ||
            state.feedbackMessage == null) {
          return;
        }
        final message = state.feedbackMessage!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tOr(message, message)),
            backgroundColor: state.feedbackIsError ? scheme.error : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context
            .read<SellerVerificationBloc>()
            .add(const ClearSellerVerificationFeedbackEvent());
      },
      builder: (context, state) {
        if (state is SellerVerificationLoading) {
          return SliverLayoutBuilder(
            builder: (context, constraints) {
              final pad = _sideInset(constraints.crossAxisExtent);
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                sliver: const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            },
          );
        }

        if (state is SellerVerificationError) {
          return SliverLayoutBuilder(
            builder: (context, constraints) {
              final pad = _sideInset(constraints.crossAxisExtent);
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                sliver: SliverToBoxAdapter(
                  child: ErrorView(
                    message: state.message,
                    retryLabel: l10n.t('retry'),
                    onRetry: () => context.read<SellerVerificationBloc>().add(
                          const LoadSellerVerificationsEvent(refresh: true),
                        ),
                  ),
                ),
              );
            },
          );
        }

        if (state is! SellerVerificationLoaded) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverMainAxisGroup(
          slivers: [
            if (state.applications.isEmpty)
              _SliverEmptyApplications(
                padBuilder: _sideInset,
                message: l10n.tOr(
                  'sellerVerificationEmpty',
                  'No seller applications match your filters.',
                ),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final pad = _sideInset(constraints.crossAxisExtent);
                  final contentWidth =
                      (constraints.crossAxisExtent - pad * 2).clamp(
                    0.0,
                    AuctionsLayoutMetrics.maxContentWidth,
                  );
                  final columns = _columnsForWidth(contentWidth);
                  final gap = screenWidth < 700 ? 8.0 : 12.0;
                  final items = state.applications;

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                    sliver: columns == 1
                        ? SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: gap),
                            itemBuilder: (context, index) => _ApplicationCard(
                              application: items[index],
                              canReview: canReview,
                              compact: compact,
                              onTap: () => _openDetail(
                                context,
                                items[index],
                                canReview,
                              ),
                            ),
                          )
                        : SliverList.builder(
                            itemCount: (items.length / columns).ceil(),
                            itemBuilder: (context, rowIndex) {
                              final start = rowIndex * columns;
                              final end =
                                  (start + columns).clamp(0, items.length);
                              final rowItems = items.sublist(start, end);
                              final rowCount =
                                  (items.length / columns).ceil();
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      rowIndex < rowCount - 1 ? gap : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < columns; i++) ...[
                                      if (i > 0) SizedBox(width: gap),
                                      Expanded(
                                        child: i < rowItems.length
                                            ? _ApplicationCard(
                                                application: rowItems[i],
                                                canReview: canReview,
                                                compact: compact,
                                                onTap: () => _openDetail(
                                                  context,
                                                  rowItems[i],
                                                  canReview,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            if (useDesktopPagination && state.total > 0)
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final pad = _sideInset(constraints.crossAxisExtent);
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
                    sliver: SliverToBoxAdapter(
                      child: AppPaginationBar(
                        currentPage: state.currentPage,
                        lastPage: state.lastPage,
                        total: state.total,
                        pageSize: SellerVerificationBloc.pageLimit,
                        itemCount: state.applications.length,
                        hideWhenSinglePage: false,
                        borderRadius: BorderRadius.circular(12),
                        onPageChanged: (page) => context
                            .read<SellerVerificationBloc>()
                            .add(GoToSellerVerificationPageEvent(page)),
                      ),
                    ),
                  );
                },
              ),
            if (!useDesktopPagination && state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    SellerVerificationApplicationEntity application,
    bool canReview,
  ) async {
    final action = await showSellerVerificationDetailSheet(
      context,
      application: application,
      canReview: canReview,
    );
    if (!context.mounted || action == null) return;

    final bloc = context.read<SellerVerificationBloc>();
    switch (action) {
      case SellerVerificationReviewAction.approve:
        final targetId = application.userId.trim().isNotEmpty
            ? application.userId.trim()
            : application.reviewTargetId;
        bloc.add(ApproveSellerVerificationEvent(targetId));
      case SellerVerificationReviewAction.reject:
        final reason = await showSellerVerificationRejectDialog(context);
        if (reason == null || !context.mounted) return;
        final targetId = application.userId.trim().isNotEmpty
            ? application.userId.trim()
            : application.reviewTargetId;
        bloc.add(
          RejectSellerVerificationEvent(
            applicationId: targetId,
            rejectionReason: reason,
          ),
        );
    }
  }
}

/// Empty state with responsive side inset.
class _SliverEmptyApplications extends StatelessWidget {
  const _SliverEmptyApplications({
    required this.padBuilder,
    required this.message,
  });

  final double Function(double extent) padBuilder;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final pad = padBuilder(constraints.crossAxisExtent);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 32, pad, 16),
          sliver: SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.canReview,
    required this.onTap,
    this.compact = false,
  });

  final SellerVerificationApplicationEntity application;
  final bool canReview;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style =
        sellerVerificationStatusStyle(scheme, l10n, application.status);
    final dateFmt = DateFormat('MMM d, yyyy');

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: compact ? 18 : 20,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: application.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              resolveMediaUrl(application.avatarUrl!) ??
                                  application.avatarUrl!,
                            )
                          : null,
                      child: application.avatarUrl == null
                          ? Icon(
                              Icons.person_outline,
                              color: scheme.onSurfaceVariant,
                              size: compact ? 18 : 22,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (application.businessName != null &&
                              application.businessName!.trim().isNotEmpty)
                            Text(
                              application.businessName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          color: style.fg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateFmt.format(application.submittedAt.toLocal()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (application.isPending && canReview) ...[
                      const SizedBox(width: 8),
                      Text(
                        l10n.tOr('review', 'Review'),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
