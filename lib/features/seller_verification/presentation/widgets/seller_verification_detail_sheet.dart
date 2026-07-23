import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/seller_verification_entities.dart';
import '../utils/seller_verification_status_style.dart';

enum SellerVerificationReviewAction { approve, reject }

Future<SellerVerificationReviewAction?> showSellerVerificationDetailSheet(
  BuildContext context, {
  required SellerVerificationApplicationEntity application,
  required bool canReview,
}) {
  final screenH = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<SellerVerificationReviewAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: screenH < 700 ? 0.92 : 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return _SellerVerificationDetailSheet(
          application: application,
          canReview: canReview,
          scrollController: scrollController,
        );
      },
    ),
  );
}

class _SellerVerificationDetailSheet extends StatelessWidget {
  const _SellerVerificationDetailSheet({
    required this.application,
    required this.canReview,
    required this.scrollController,
  });

  final SellerVerificationApplicationEntity application;
  final bool canReview;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final style =
        sellerVerificationStatusStyle(scheme, l10n, application.status);
    final dateFmt = DateFormat('MMM d, yyyy • HH:mm');
    final docUrl = application.documentUrl != null
        ? resolveMediaUrl(application.documentUrl!)
        : null;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: application.avatarUrl != null
                        ? CachedNetworkImageProvider(
                            resolveMediaUrl(application.avatarUrl!) ??
                                application.avatarUrl!,
                          )
                        : null,
                    child: application.avatarUrl == null
                        ? Icon(Icons.person, color: scheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (application.businessName != null)
                          Text(
                            application.businessName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      style.label,
                      style: TextStyle(
                        color: style.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoTile(
                icon: Icons.schedule_outlined,
                label: l10n.tOr('submittedAt', 'Submitted'),
                value: dateFmt.format(application.submittedAt.toLocal()),
              ),
              if (application.reviewedAt != null)
                _InfoTile(
                  icon: Icons.fact_check_outlined,
                  label: l10n.tOr('reviewedAt', 'Reviewed'),
                  value: dateFmt.format(application.reviewedAt!.toLocal()),
                ),
              if (application.documentType != null)
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: l10n.tOr('documentType', 'Document type'),
                  value: application.documentType!,
                ),
              if (application.additionalNotes != null &&
                  application.additionalNotes!.trim().isNotEmpty)
                _InfoTile(
                  icon: Icons.notes_outlined,
                  label: l10n.tOr('notes', 'Notes'),
                  value: application.additionalNotes!,
                ),
              if (application.rejectionReason != null &&
                  application.rejectionReason!.trim().isNotEmpty)
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: l10n.tOr('rejectionReason', 'Rejection reason'),
                  value: application.rejectionReason!,
                  valueColor: scheme.error,
                ),
              if (docUrl != null && docUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.tOr('verificationDocument', 'Verification document'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: docUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (application.isPending && canReview) ...[
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 420;
                    final approveBtn = FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        SellerVerificationReviewAction.approve,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(l10n.tOr('approveSeller', 'Approve')),
                    );
                    final rejectBtn = OutlinedButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        SellerVerificationReviewAction.reject,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(l10n.tOr('rejectSeller', 'Reject')),
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          approveBtn,
                          const SizedBox(height: 10),
                          rejectBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: rejectBtn),
                        const SizedBox(width: 12),
                        Expanded(child: approveBtn),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: valueColor ?? scheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
