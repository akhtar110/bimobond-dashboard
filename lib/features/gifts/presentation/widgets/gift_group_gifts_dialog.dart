import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/usecases/get_admin_gifts_usecase.dart';

class GiftGroupGiftsDialog extends StatefulWidget {
  const GiftGroupGiftsDialog({
    super.key,
    required this.groupName,
    required this.initialMembers,
  });

  final String groupName;
  final List<GiftGroupMemberEntity> initialMembers;

  static Future<List<GiftGroupMembershipItem>?> show(
    BuildContext context, {
    required String groupName,
    required List<GiftGroupMemberEntity> initialMembers,
  }) {
    return showDialog<List<GiftGroupMembershipItem>>(
      context: context,
      builder: (_) => GiftGroupGiftsDialog(
        groupName: groupName,
        initialMembers: initialMembers,
      ),
    );
  }

  @override
  State<GiftGroupGiftsDialog> createState() => _GiftGroupGiftsDialogState();
}

class _GiftGroupGiftsDialogState extends State<GiftGroupGiftsDialog> {
  final _searchController = TextEditingController();
  final _orderedIds = <String>[];
  final _available = <GiftEntity>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final sorted = [...widget.initialMembers]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _orderedIds.addAll(sorted.map((member) => member.gift.id));
    _loadGifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gifts = await di.sl<GetAdminGifts>()();
      if (!mounted) return;
      setState(() {
        _available
          ..clear()
          ..addAll(gifts);
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

  List<GiftEntity> get _filteredAvailable {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _available;
    return _available
        .where((gift) => gift.name.toLowerCase().contains(q))
        .toList();
  }

  void _toggleGift(String giftId) {
    setState(() {
      if (_orderedIds.contains(giftId)) {
        _orderedIds.remove(giftId);
      } else {
        _orderedIds.add(giftId);
      }
    });
  }

  void _save() {
    final items = [
      for (var i = 0; i < _orderedIds.length; i++)
        GiftGroupMembershipItem(giftId: _orderedIds[i], sortOrder: i),
    ];
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('giftGroupManageGiftsTitle', 'Manage gifts')),
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
                hintText: l10n.tOr('searchGifts', 'Search gifts…'),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tOr('giftGroupSelectedCount', '{count} selected')
                  .replaceAll('{count}', '${_orderedIds.length}'),
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
                          ? Center(
                              child: Text(
                                l10n.tOr('noGiftsFound', 'No gifts found'),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredAvailable.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final gift = _filteredAvailable[index];
                                final selected =
                                    _orderedIds.contains(gift.id);
                                final order = selected
                                    ? _orderedIds.indexOf(gift.id) + 1
                                    : null;
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (_) => _toggleGift(gift.id),
                                  secondary: order != null
                                      ? CircleAvatar(
                                          radius: 12,
                                          child: Text(
                                            '$order',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        )
                                      : null,
                                  title: Text(
                                    gift.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('${gift.priceCoins} coins'),
                                );
                              },
                            ),
            ),
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
