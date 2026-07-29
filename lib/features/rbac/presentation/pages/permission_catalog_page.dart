import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/permission_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/rbac_responsive.dart';
import '../widgets/rbac_ui.dart';

/// Layout buckets for the catalog rows.
enum _CatalogLayout { mobile, tablet, desktop }

class PermissionCatalogPage extends StatefulWidget {
  const PermissionCatalogPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PermissionCatalogPage> createState() => _PermissionCatalogPageState();
}

class _PermissionCatalogPageState extends State<PermissionCatalogPage> {
  String _query = '';
  final Set<String> _collapsedGroups = {};
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>().add(const LoadPermissions());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PermissionEntity> _visible(List<PermissionEntity> permissions) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return permissions;
    return permissions
        .where(
          (permission) =>
              permission.label.toLowerCase().contains(query) ||
              permission.key.toLowerCase().contains(query) ||
              permission.group.toLowerCase().contains(query) ||
              permission.action.toLowerCase().contains(query) ||
              (permission.description ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Map<String, List<PermissionEntity>> _grouped(
    List<PermissionEntity> permissions,
  ) {
    final groups = <String, List<PermissionEntity>>{};
    for (final permission in permissions) {
      groups.putIfAbsent(permission.group, () => []).add(permission);
    }
    final keys = groups.keys.toList()..sort();
    return {for (final key in keys) key: groups[key]!};
  }

  bool _isExpanded(String group) =>
      _query.trim().isNotEmpty || !_collapsedGroups.contains(group);

  void _toggleGroup(String group) {
    setState(() {
      _collapsedGroups.contains(group)
          ? _collapsedGroups.remove(group)
          : _collapsedGroups.add(group);
    });
  }

  void _expandAll(Iterable<String> groups) {
    setState(() => _collapsedGroups.clear());
  }

  void _collapseAll(Iterable<String> groups) {
    setState(() {
      _collapsedGroups
        ..clear()
        ..addAll(groups);
    });
  }

  Future<void> _copyKey(BuildContext context, String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.tOr('permissionKeyCopied', 'Permission key copied'),
        ),
        backgroundColor: scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final metrics = RbacLayoutMetrics(
      getRbacDeviceType(MediaQuery.sizeOf(context).width),
    );
    final compact = metrics.isCompact;

    return BlocBuilder<RbacBloc, RbacState>(
      builder: (context, state) {
        final all = state.permissions;
        final permissions = _visible(all);
        final groups = _grouped(permissions);
        final isLoading =
            state.status == RbacStatus.loading && state.permissions.isEmpty;

        return RbacPageFrame(
          title: l10n.tOr('permissionCatalog', 'Permission catalog'),
          metrics: metrics,
          onBack: widget.onBack,
          actions: [
            if (!isLoading && groups.isNotEmpty) ...[
              RbacHeaderAction(
                compact: metrics.useIconActions,
                icon: Icons.unfold_more_rounded,
                label: l10n.tOr('expandAll', 'Expand all'),
                onPressed: () => _expandAll(groups.keys),
              ),
              RbacHeaderAction(
                compact: metrics.useIconActions,
                icon: Icons.unfold_less_rounded,
                label: l10n.tOr('collapseAll', 'Collapse all'),
                onPressed: () => _collapseAll(groups.keys),
              ),
            ],
            IconButton.filledTonal(
              onPressed: () =>
                  context.read<RbacBloc>().add(const LoadPermissions()),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.tOr('refresh', 'Refresh'),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                minimumSize: Size(
                  metrics.useIconActions ? 36 : 40,
                  metrics.useIconActions ? 36 : 40,
                ),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OverviewStrip(
                total: all.length,
                groups: _grouped(all).length,
                visible: permissions.length,
                compact: compact,
              ),
              SizedBox(height: metrics.sectionGap),
              TextField(
                controller: _searchCtrl,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.tOr(
                    'searchPermissions',
                    'Search by label, key, group, or action…',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: l10n.tOr('clear', 'Clear'),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 1.4),
                  ),
                ),
              ),
              SizedBox(height: metrics.sectionGap),
              Expanded(child: _body(context, state, permissions, groups)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    RbacState state,
    List<PermissionEntity> permissions,
    Map<String, List<PermissionEntity>> groups,
  ) {
    final l10n = context.l10n;

    if (state.status == RbacStatus.loading && state.permissions.isEmpty) {
      return const _CatalogSkeleton();
    }
    if (state.status == RbacStatus.failure && state.permissions.isEmpty) {
      return RbacErrorView(
        message: state.errorMessage == null
            ? l10n.tOr(
                'rbacPermissionsLoadFailed',
                'Unable to load permissions',
              )
            : rbacErrorText(context, state.errorMessage!),
        onRetry: () => context.read<RbacBloc>().add(const LoadPermissions()),
      );
    }
    if (permissions.isEmpty) {
      return RbacEmptyView(
        title: l10n.tOr('noPermissionsFound', 'No permissions found'),
        icon: Icons.policy_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.maxWidth >= 980
            ? _CatalogLayout.desktop
            : constraints.maxWidth >= 640
                ? _CatalogLayout.tablet
                : _CatalogLayout.mobile;

        return CustomScrollView(
          slivers: [
            for (final entry in groups.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PermissionGroupCard(
                    group: entry.key,
                    permissions: entry.value,
                    expanded: _isExpanded(entry.key),
                    layout: layout,
                    onToggle: () => _toggleGroup(entry.key),
                    onCopyKey: (key) => _copyKey(context, key),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({
    required this.total,
    required this.groups,
    required this.visible,
    required this.compact,
  });

  final int total;
  final int groups;
  final int visible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final cards = [
      _KpiChip(
        icon: Icons.policy_outlined,
        label: l10n.tOr('totalPermissions', 'Total'),
        value: '$total',
        color: scheme.primary,
      ),
      _KpiChip(
        icon: Icons.folder_outlined,
        label: l10n.tOr('permissionGroups', 'Groups'),
        value: '$groups',
        color: scheme.tertiary,
      ),
      _KpiChip(
        icon: Icons.filter_alt_outlined,
        label: l10n.tOr('showingResults', 'Showing'),
        value: '$visible',
        color: scheme.secondary,
      ),
    ];

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cards,
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({
    required this.group,
    required this.permissions,
    required this.expanded,
    required this.layout,
    required this.onToggle,
    required this.onCopyKey,
  });

  final String group;
  final List<PermissionEntity> permissions;
  final bool expanded;
  final _CatalogLayout layout;
  final VoidCallback onToggle;
  final ValueChanged<String> onCopyKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(expanded ? 0 : 16),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder_special_outlined,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${permissions.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
            for (var i = 0; i < permissions.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              _PermissionRow(
                permission: permissions[i],
                layout: layout,
                onCopyKey: onCopyKey,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.permission,
    required this.layout,
    required this.onCopyKey,
  });

  final PermissionEntity permission;
  final _CatalogLayout layout;
  final ValueChanged<String> onCopyKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final copyButton = IconButton(
      onPressed: () => onCopyKey(permission.key),
      icon: const Icon(Icons.copy_rounded, size: 18),
      tooltip: l10n.tOr('copyPermissionKey', 'Copy permission key'),
      visualDensity: VisualDensity.compact,
    );

    final keyChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: SelectableText(
        permission.key,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );

    final actionChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        permission.action.isNotEmpty ? permission.action : '—',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (layout == _CatalogLayout.mobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permission.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [keyChip, actionChip],
                  ),
                  if (permission.description != null &&
                      permission.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      permission.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            copyButton,
          ],
        ),
      );
    }

    if (layout == _CatalogLayout.tablet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permission.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (permission.description != null &&
                      permission.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      permission.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: keyChip,
              ),
            ),
            const SizedBox(width: 10),
            actionChip,
            copyButton,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              permission.label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: keyChip,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 96, child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: actionChip,
          )),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              (permission.description?.trim().isNotEmpty ?? false)
                  ? permission.description!
                  : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          copyButton,
        ],
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
        );
      },
    );
  }
}
