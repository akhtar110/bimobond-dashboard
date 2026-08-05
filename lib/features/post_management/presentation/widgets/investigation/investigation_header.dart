import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import 'copyable_post_id_row.dart';
import 'investigation_theme.dart';

class InvestigationHeader extends StatelessWidget {
  const InvestigationHeader({
    super.key,
    required this.onBack,
    this.onExport,
    this.exportEnabled = false,
    this.postId,
  });

  final VoidCallback onBack;
  final VoidCallback? onExport;
  final bool exportEnabled;
  final String? postId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.fromLTRB(
        width < InvestigationTheme.compact ? 12 : (width < InvestigationTheme.tablet ? 16 : 24),
        12,
        width < InvestigationTheme.compact ? 12 : (width < InvestigationTheme.tablet ? 16 : 24),
        16,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  tooltip: l10n.t('back'),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    l10n.t('postManagementDetails'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (onExport != null)
                  IconButton(
                    onPressed: exportEnabled ? onExport : null,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    tooltip: l10n.tOr('postDetailExport', 'Export post details'),
                  ),
              ],
            ),
            if (postId != null && postId!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CopyablePostIdRow(postId: postId!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
