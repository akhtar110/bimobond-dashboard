import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/permission_entity.dart';

class PermissionSelector extends StatefulWidget {
  const PermissionSelector({
    super.key,
    required this.permissions,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PermissionEntity> permissions;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  @override
  State<PermissionSelector> createState() => _PermissionSelectorState();
}

class _PermissionSelectorState extends State<PermissionSelector> {
  String _query = '';
  final Set<String> _expandedGroups = {};

  Map<String, List<PermissionEntity>> get _groups {
    final result = <String, List<PermissionEntity>>{};
    final query = _query.trim().toLowerCase();
    for (final permission in widget.permissions) {
      final matches =
          query.isEmpty ||
          permission.label.toLowerCase().contains(query) ||
          permission.key.toLowerCase().contains(query) ||
          permission.action.toLowerCase().contains(query) ||
          (permission.description ?? '').toLowerCase().contains(query);
      if (matches) {
        result.putIfAbsent(permission.group, () => []).add(permission);
      }
    }
    return result;
  }

  void _toggle(PermissionEntity permission, bool selected) {
    final next = Set<String>.of(widget.selectedIds);
    selected ? next.add(permission.id) : next.remove(permission.id);
    widget.onChanged(next);
  }

  void _toggleGroup(List<PermissionEntity> permissions, bool selected) {
    final next = Set<String>.of(widget.selectedIds);
    final ids = permissions.map((permission) => permission.id);
    selected ? next.addAll(ids) : next.removeAll(ids);
    widget.onChanged(next);
  }

  void _selectAllVisible() {
    final next = Set<String>.of(widget.selectedIds);
    for (final group in _groups.values) {
      next.addAll(group.map((p) => p.id));
    }
    widget.onChanged(next);
  }

  void _clearAll() => widget.onChanged(<String>{});

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: context.l10n.tOr(
              'searchPermissions',
              'Search permissions',
            ),
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: !widget.enabled || groups.isEmpty
                  ? null
                  : _selectAllVisible,
              child: Text(context.l10n.tOr('selectAll', 'Select all')),
            ),
            TextButton(
              onPressed: !widget.enabled || widget.selectedIds.isEmpty
                  ? null
                  : _clearAll,
              child: Text(context.l10n.tOr('clearAll', 'Clear all')),
            ),
            const Spacer(),
            Text(
              '${widget.selectedIds.length} '
              '${context.l10n.tOr('selected', 'selected')}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: Text(
              context.l10n.tOr('noPermissionsFound', 'No permissions found'),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...groups.entries.map((entry) {
            final isExpanded =
                _query.isNotEmpty || _expandedGroups.contains(entry.key);
            final selectedCount = entry.value
                .where(
                  (permission) => widget.selectedIds.contains(permission.id),
                )
                .length;
            final allSelected = selectedCount == entry.value.length;
            return Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) => setState(() {
                  expanded
                      ? _expandedGroups.add(entry.key)
                      : _expandedGroups.remove(entry.key);
                }),
                leading: Checkbox(
                  value: allSelected
                      ? true
                      : selectedCount > 0
                      ? null
                      : false,
                  tristate: true,
                  onChanged: widget.enabled
                      ? (value) => _toggleGroup(entry.value, value ?? false)
                      : null,
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '$selectedCount / ${entry.value.length} '
                  '${context.l10n.tOr('selected', 'selected')}',
                ),
                children: entry.value
                    .map(
                      (permission) => CheckboxListTile(
                        dense: true,
                        value: widget.selectedIds.contains(permission.id),
                        onChanged: widget.enabled
                            ? (value) => _toggle(permission, value ?? false)
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(permission.label),
                        subtitle: Text(
                          permission.key,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          }),
      ],
    );
  }
}
