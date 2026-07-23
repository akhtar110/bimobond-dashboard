import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

class SoundGroupSoundsDialog extends StatefulWidget {
  const SoundGroupSoundsDialog({
    super.key,
    required this.groupName,
    required this.initialMembers,
  });

  final String groupName;
  final List<SoundGroupMemberEntity> initialMembers;

  static Future<List<SoundGroupMembershipItem>?> show(
    BuildContext context, {
    required String groupName,
    required List<SoundGroupMemberEntity> initialMembers,
  }) {
    return showDialog<List<SoundGroupMembershipItem>>(
      context: context,
      builder: (_) => SoundGroupSoundsDialog(
        groupName: groupName,
        initialMembers: initialMembers,
      ),
    );
  }

  @override
  State<SoundGroupSoundsDialog> createState() => _SoundGroupSoundsDialogState();
}

class _SoundGroupSoundsDialogState extends State<SoundGroupSoundsDialog> {
  final _searchController = TextEditingController();
  final _orderedIds = <String>[];
  final _available = <SoundEntity>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final sorted = [...widget.initialMembers]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _orderedIds.addAll(sorted.map((member) => member.sound.id));
    _loadSounds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSounds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await di.sl<GetSoundsUseCase>()(
        const SoundsQuery(page: 1, limit: 100, sort: SoundSortMode.trending),
      );
      if (!mounted) return;
      setState(() {
        _available
          ..clear()
          ..addAll(page.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<SoundEntity> get _filteredAvailable {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _available;
    return _available
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.author.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSound(String soundId) {
    setState(() {
      if (_orderedIds.contains(soundId)) {
        _orderedIds.remove(soundId);
      } else {
        _orderedIds.add(soundId);
      }
    });
  }

  void _save() {
    final items = [
      for (var i = 0; i < _orderedIds.length; i++)
        SoundGroupMembershipItem(soundId: _orderedIds[i], sortOrder: i),
    ];
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.tOr('soundGroupManageSoundsTitle', 'Manage sounds')),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.groupName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.t('soundSearchHint'),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tOr(
                'soundGroupSelectedCount',
                '{count} selected',
              ).replaceAll('{count}', '${_orderedIds.length}'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
                          ),
                        )
                      : _filteredAvailable.isEmpty
                          ? Center(child: Text(l10n.t('soundNoResults')))
                          : ListView.separated(
                              itemCount: _filteredAvailable.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final sound = _filteredAvailable[index];
                                final selected = _orderedIds.contains(sound.id);
                                final order = selected
                                    ? _orderedIds.indexOf(sound.id) + 1
                                    : null;
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (_) => _toggleSound(sound.id),
                                  secondary: order != null
                                      ? CircleAvatar(
                                          radius: 12,
                                          child: Text(
                                            '$order',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        )
                                      : null,
                                  title: Text(
                                    sound.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${sound.author} · ${sound.useCount}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
            ),
            if (_orderedIds.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                l10n.tOr(
                  'soundGroupOrderHint',
                  'Selection order defines shelf order (top to bottom).',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: Text(l10n.t('save')),
        ),
      ],
    );
  }
}
