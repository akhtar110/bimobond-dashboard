import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';

void showPublishCatalogDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: const PublishCatalogDialog(),
    ),
  );
}

class PublishCatalogDialog extends StatefulWidget {
  const PublishCatalogDialog({super.key});

  @override
  State<PublishCatalogDialog> createState() => _PublishCatalogDialogState();
}

class _PublishCatalogDialogState extends State<PublishCatalogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _versionCtrl;
  late final TextEditingController _notesCtrl;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _versionCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = context.read<FiltersEffectsBloc>().state;
    if (state is FiltersEffectsLoaded) {
      final version = state.catalog?.version ?? state.overview?.catalogVersion;
      if (version != null && version.isNotEmpty) {
        _versionCtrl.text = version;
      }
    }
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<FiltersEffectsBloc>().add(
      PublishFiltersEffectsCatalogEvent(
        PublishCatalogRequest(
          version: _versionCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.tOr('fePublishCatalog', 'Publish catalog')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.tOr(
                  'fePublishCatalogHint',
                  'Publish the current filter and effect catalog for mobile clients.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _versionCtrl,
                maxLength: 40,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldVersion', 'Version'),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return l10n.tOr('feRequired', 'Required');
                  }
                  if (value.length > 40) {
                    return l10n.tOr(
                      'feVersionTooLong',
                      'Version must be 40 characters or fewer',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldNotes', 'Notes'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.publish_rounded, size: 18),
          label: Text(l10n.tOr('fePublish', 'Publish')),
        ),
      ],
    );
  }
}
