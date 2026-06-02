import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        if (form.inferredType == 'VIDEO') ...[
          const SizedBox(height: 16),
          _VideoMetaFields(form: form, onFieldUpdate: onFieldUpdate),
        ],
      ],
    );
  }
}

class _VideoMetaFields extends StatelessWidget {
  const _VideoMetaFields({
    required this.form,
    required this.onFieldUpdate,
  });

  final CreatePostEntity form;
  final CreatePostFieldUpdater onFieldUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final fields = [
          _NumberField(
            label: l10n.t('videoDuration'),
            value: form.duration,
            onChanged: (v) => onFieldUpdate(CreatePostField.duration, v),
          ),
          _NumberField(
            label: l10n.t('videoWidth'),
            value: form.videoWidth,
            onChanged: (v) => onFieldUpdate(CreatePostField.videoWidth, v),
          ),
          _NumberField(
            label: l10n.t('videoHeight'),
            value: form.videoHeight,
            onChanged: (v) => onFieldUpdate(CreatePostField.videoHeight, v),
          ),
        ];
        if (narrow) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                fields[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 8),
            Expanded(child: fields[1]),
            const SizedBox(width: 8),
            Expanded(child: fields[2]),
          ],
        );
      },
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

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final text = widget.value?.toString() ?? '';
      if (_controller.text != text) _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (v) {
        widget.onChanged(v.isEmpty ? null : int.tryParse(v));
      },
    );
  }
}
