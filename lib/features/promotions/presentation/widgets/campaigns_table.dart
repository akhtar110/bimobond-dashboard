import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/promotion_entities.dart';
import 'campaign_action_dialogs.dart';
import 'promotions_dashboard_widgets.dart';
import 'promotions_shared_widgets.dart';

const double kCampaignsTableHeaderHeight = 40;
const double _kCellHPad = 10;
const double _kRowVPad = 10;

enum CampaignsTableDensity { wide, medium, narrow, compact }

CampaignsTableDensity campaignsTableDensityForWidth(double width) {
  if (width >= 1200) return CampaignsTableDensity.wide;
  if (width >= 900) return CampaignsTableDensity.medium;
  if (width >= 560) return CampaignsTableDensity.narrow;
  return CampaignsTableDensity.compact;
}

double _campaignsTableCheckboxWidth(CampaignsTableDensity density) =>
    density == CampaignsTableDensity.compact ? 28.0 : 34.0;

double _campaignsTableCellHPad(CampaignsTableDensity density) =>
    switch (density) {
      CampaignsTableDensity.compact => 4.0,
      CampaignsTableDensity.narrow => 6.0,
      _ => _kCellHPad,
    };

double _campaignsTableRowHPad(CampaignsTableDensity density) =>
    density == CampaignsTableDensity.compact ? 6.0 : 10.0;

class CampaignsTable extends StatelessWidget {
  const CampaignsTable({
    super.key,
    required this.campaigns,
    required this.selectedIds,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.currency,
    required this.dateFmt,
    required this.onSelectAll,
    required this.onToggle,
    required this.onOpen,
    required this.onStatus,
    required this.onDelete,
    this.showProgress = false,
    this.readOnly = false,
  });

  final List<CampaignEntity> campaigns;
  final Set<String> selectedIds;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final VoidCallback onSelectAll;
  final ValueChanged<String> onToggle;
  final ValueChanged<CampaignEntity> onOpen;
  final void Function(String campaignId, String status) onStatus;
  final ValueChanged<String> onDelete;
  final bool showProgress;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PromotionsSpace.xl),
            child: Text(context.l10n.t('noData')),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final density =
            campaignsTableDensityForWidth(constraints.maxWidth);
        final scheme = Theme.of(context).colorScheme;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampaignsTableHeader(
                  density: density,
                  allVisibleSelected: allVisibleSelected,
                  someVisibleSelected: someVisibleSelected,
                  onSelectAll: onSelectAll,
                  readOnly: readOnly,
                ),
                if (showProgress) const LinearProgressIndicator(),
                for (var i = 0; i < campaigns.length; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == campaigns.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                    ),
                    child: CampaignsTableRow(
                      campaign: campaigns[i],
                      density: density,
                      isSelected: selectedIds.contains(campaigns[i].id),
                      currency: currency,
                      dateFmt: dateFmt,
                      readOnly: readOnly,
                      onToggle: () => onToggle(campaigns[i].id),
                      onOpen: () => onOpen(campaigns[i]),
                      onStatus: (status) =>
                          onStatus(campaigns[i].id, status),
                      onDelete: () => onDelete(campaigns[i].id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CampaignsTableHeader extends StatelessWidget {
  const CampaignsTableHeader({
    super.key,
    required this.density,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.onSelectAll,
    this.readOnly = false,
  });

  final CampaignsTableDensity density;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final VoidCallback onSelectAll;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 0.1,
        );

    return Container(
      height: kCampaignsTableHeaderHeight,
      color: scheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(horizontal: _campaignsTableRowHPad(density)),
      child: _CampaignsTableRowLayout(
        density: density,
        checkbox: readOnly
            ? const SizedBox.shrink()
            : Checkbox(
                tristate: true,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: allVisibleSelected
                    ? true
                    : someVisibleSelected
                        ? null
                        : false,
                onChanged: (_) => onSelectAll(),
              ),
        owner: Text(l10n.t('owner'), style: style),
        objective: density == CampaignsTableDensity.narrow ||
                density == CampaignsTableDensity.compact
            ? const SizedBox.shrink()
            : Text(l10n.t('promoObjective'), style: style),
        package: density != CampaignsTableDensity.narrow &&
                density != CampaignsTableDensity.compact
            ? Text(l10n.t('promoPackage'), style: style)
            : const SizedBox.shrink(),
        status: Text(l10n.t('status'), style: style),
        budget: Text(l10n.t('promoBudget'), style: style),
        spent: density != CampaignsTableDensity.narrow &&
                density != CampaignsTableDensity.compact
            ? Text(l10n.t('promoSpent'), style: style)
            : const SizedBox.shrink(),
        progress: Text(l10n.t('promoProgress'), style: style),
        created: density == CampaignsTableDensity.wide
            ? Text(l10n.t('createdAt'), style: style)
            : const SizedBox.shrink(),
        actions: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class CampaignsTableRow extends StatelessWidget {
  const CampaignsTableRow({
    super.key,
    required this.campaign,
    required this.density,
    required this.isSelected,
    required this.currency,
    required this.dateFmt,
    required this.onToggle,
    required this.onOpen,
    required this.onStatus,
    required this.onDelete,
    this.readOnly = false,
  });

  final CampaignEntity campaign;
  final CampaignsTableDensity density;
  final bool isSelected;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;
  final bool readOnly;

  Future<void> _changeStatus(BuildContext context, String status) async {
    final confirmed =
        await confirmCampaignStatusChange(context, status: status);
    if (!confirmed || !context.mounted) return;
    onStatus(status);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmCampaignDelete(context);
    if (!confirmed || !context.mounted) return;
    onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final scheme = Theme.of(context).colorScheme;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
        );
    final numericStyle = cellStyle?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final bg = isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : scheme.surface;

    final ownerName = c.user?.displayName ?? c.userId;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onOpen,
        hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _campaignsTableRowHPad(density),
            vertical: density == CampaignsTableDensity.compact ? 8 : _kRowVPad,
          ),
          child: _CampaignsTableRowLayout(
            density: density,
            checkbox: readOnly
                ? const SizedBox.shrink()
                : Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
            owner: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ownerName,
                    maxLines: density == CampaignsTableDensity.narrow ||
                            density == CampaignsTableDensity.compact
                        ? 1
                        : 2,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (density == CampaignsTableDensity.narrow ||
                      density == CampaignsTableDensity.compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.objective,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            objective: density == CampaignsTableDensity.narrow ||
                    density == CampaignsTableDensity.compact
                ? const SizedBox.shrink()
                : Text(
                    c.objective,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle,
                  ),
            package: density != CampaignsTableDensity.narrow &&
                    density != CampaignsTableDensity.compact
                ? Text(
                    c.package?.name ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle,
                  )
                : const SizedBox.shrink(),
            status: CampaignStatusBadge(status: c.status),
            budget: Text(
              CoinFormat.coins(c.budgetCoins),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: numericStyle,
            ),
            spent: density != CampaignsTableDensity.narrow &&
                    density != CampaignsTableDensity.compact
                ? Text(
                    CoinFormat.coins(c.spentCoins),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: numericStyle,
                  )
                : const SizedBox.shrink(),
            progress: Text(
              '${c.progressPercent.toStringAsFixed(1)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: numericStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            created: density == CampaignsTableDensity.wide
                ? Text(
                    dateFmt.format(c.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  )
                : const SizedBox.shrink(),
            actions: readOnly
                ? const SizedBox.shrink()
                : _CampaignRowActions(
                    onPause: () => _changeStatus(context, 'PAUSED'),
                    onActivate: () => _changeStatus(context, 'ACTIVE'),
                    onReject: () => _changeStatus(context, 'REJECTED'),
                    onOpen: onOpen,
                    onDelete: () => _delete(context),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CampaignsTableRowLayout extends StatelessWidget {
  const _CampaignsTableRowLayout({
    required this.density,
    required this.checkbox,
    required this.owner,
    required this.objective,
    required this.package,
    required this.status,
    required this.budget,
    required this.spent,
    required this.progress,
    required this.created,
    required this.actions,
  });

  final CampaignsTableDensity density;
  final Widget checkbox;
  final Widget owner;
  final Widget objective;
  final Widget package;
  final Widget status;
  final Widget budget;
  final Widget spent;
  final Widget progress;
  final Widget created;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final showObjective = density != CampaignsTableDensity.narrow &&
        density != CampaignsTableDensity.compact;
    final showPackage = density != CampaignsTableDensity.narrow &&
        density != CampaignsTableDensity.compact;
    final showSpent = density != CampaignsTableDensity.narrow &&
        density != CampaignsTableDensity.compact;
    final showCreated = density == CampaignsTableDensity.wide;
    final checkboxWidth = _campaignsTableCheckboxWidth(density);
    final cellHPad = _campaignsTableCellHPad(density);
    final actionsWidth = density == CampaignsTableDensity.compact ? 32.0 : 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: checkboxWidth, child: checkbox),
        Expanded(flex: density == CampaignsTableDensity.compact ? 5 : 4, child: _cell(owner, cellHPad)),
        if (showObjective) Expanded(flex: 2, child: _cell(objective, cellHPad)),
        if (showPackage) Expanded(flex: 2, child: _cell(package, cellHPad)),
        Expanded(
          flex: density == CampaignsTableDensity.compact ? 2 : 2,
          child: _cell(
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: status,
            ),
            cellHPad,
          ),
        ),
        Expanded(flex: 1, child: _cell(budget, cellHPad, alignEnd: true)),
        if (showSpent) Expanded(flex: 1, child: _cell(spent, cellHPad, alignEnd: true)),
        Expanded(flex: 1, child: _cell(progress, cellHPad, alignEnd: true)),
        if (showCreated) Expanded(flex: 2, child: _cell(created, cellHPad)),
        SizedBox(width: actionsWidth, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child, double horizontalPadding, {bool alignEnd = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _CampaignRowActions extends StatelessWidget {
  const _CampaignRowActions({
    required this.onPause,
    required this.onActivate,
    required this.onReject,
    required this.onOpen,
    required this.onDelete,
  });

  final VoidCallback onPause;
  final VoidCallback onActivate;
  final VoidCallback onReject;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (value) {
        switch (value) {
          case 'pause':
            onPause();
          case 'activate':
            onActivate();
          case 'reject':
            onReject();
          case 'open':
            onOpen();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pause',
          child: Row(
            children: [
              const Icon(Icons.pause_circle_outline, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoPause')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'activate',
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoActivate')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reject',
          child: Row(
            children: [
              Icon(Icons.block, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Text(l10n.t('promoReject')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 18),
              const SizedBox(width: 8),
              Text(l10n.t('promoCampaignDetail')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Text(
                l10n.t('delete'),
                style: TextStyle(color: scheme.error),
              ),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}
