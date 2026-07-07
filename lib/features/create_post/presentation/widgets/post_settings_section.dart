import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import 'create_post_field_listener.dart';
import 'post_auction_section.dart';

class PostSettingsSection extends StatelessWidget {
  const PostSettingsSection({
    super.key,
    required this.form,
    required this.onFieldUpdate,
  });

  final CreatePostEntity form;
  final CreatePostFieldUpdater onFieldUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(form.privacyStatus),
          initialValue: form.privacyStatus,
          decoration: InputDecoration(
            labelText: l10n.t('privacyStatus'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'PUBLIC',
              child: Text(l10n.t('privacyPublic')),
            ),
            DropdownMenuItem(
              value: 'PRIVATE',
              child: Text(l10n.t('privacyPrivate')),
            ),
            DropdownMenuItem(
              value: 'FRIENDS',
              child: Text(l10n.t('privacyFriends')),
            ),
          ],
          onChanged: (v) {
            if (v != null) onFieldUpdate(CreatePostField.privacyStatus, v);
          },
        ),
        const SizedBox(height: 12),
        _SwitchRow(
          label: l10n.t('allowComments'),
          value: form.allowComments,
          onChanged: (v) => onFieldUpdate(CreatePostField.allowComments, v),
        ),
        _SwitchRow(
          label: l10n.t('allowDuets'),
          value: form.allowDuets,
          onChanged: (v) => onFieldUpdate(CreatePostField.allowDuets, v),
        ),
        _SwitchRow(
          label: l10n.t('allowStitch'),
          value: form.allowStitch,
          onChanged: (v) => onFieldUpdate(CreatePostField.allowStitch, v),
        ),
        _SwitchRow(
          label: l10n.t('isStory'),
          value: form.isStory,
          onChanged: (v) => onFieldUpdate(CreatePostField.isStory, v),
        ),
        _SwitchRow(
          label: l10n.t('isAuctionable'),
          value: form.isAuctionable,
          onChanged: (v) => onFieldUpdate(CreatePostField.isAuctionable, v),
        ),
        PostAuctionSection(form: form, onFieldUpdate: onFieldUpdate),
        _SwitchRow(
          label: l10n.t('isAd'),
          value: form.isAd,
          onChanged: (v) => onFieldUpdate(CreatePostField.isAd, v),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}
