import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/settings_admin_entities.dart';
import '../bloc/admin_settings_bloc.dart';

/// Branding form with logo preview and save action.
class BrandingTab extends StatefulWidget {
  const BrandingTab({super.key});

  @override
  State<BrandingTab> createState() => _BrandingTabState();
}

class _BrandingTabState extends State<BrandingTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _appNameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _logoUrlController;
  String? _loadedId;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _taglineController = TextEditingController();
    _supportEmailController = TextEditingController();
    _logoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _taglineController.dispose();
    _supportEmailController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  void _syncFromBranding(AppBrandingEntity? branding) {
    if (branding == null || branding.id == _loadedId) return;
    _loadedId = branding.id;
    _appNameController.text = branding.appName;
    _taglineController.text = branding.tagline ?? '';
    _supportEmailController.text = branding.supportEmail ?? '';
    _logoUrlController.text = branding.logoUrl ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminSettingsBloc>().add(
          UpdateAdminBrandingEvent(
            appName: _appNameController.text.trim(),
            tagline: _taglineController.text.trim().isEmpty
                ? null
                : _taglineController.text.trim(),
            supportEmail: _supportEmailController.text.trim().isEmpty
                ? null
                : _supportEmailController.text.trim(),
            logoUrl: _logoUrlController.text.trim().isEmpty
                ? null
                : _logoUrlController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canWrite = PermissionManager.canWriteSettings(context);

    return BlocConsumer<AdminSettingsBloc, AdminSettingsState>(
      listenWhen: (prev, next) => prev.branding?.id != next.branding?.id,
      listener: (context, state) => _syncFromBranding(state.branding),
      builder: (context, state) {
        _syncFromBranding(state.branding);

        final logoUrl = _logoUrlController.text.trim();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoPreview(url: logoUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _appNameController,
                              enabled: canWrite && !state.isSaving,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? l10n.tOr(
                                          'settingsAppNameRequired',
                                          'App name is required',
                                        )
                                      : null,
                              decoration: InputDecoration(
                                labelText: l10n.tOr('settingsAppName', 'App name'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taglineController,
                              enabled: canWrite && !state.isSaving,
                              decoration: InputDecoration(
                                labelText: l10n.tOr('settingsTagline', 'Tagline'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _supportEmailController,
                    enabled: canWrite && !state.isSaving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.tOr('settingsSupportEmail', 'Support email'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _logoUrlController,
                    enabled: canWrite && !state.isSaving,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.tOr('settingsLogoUrl', 'Logo URL'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (canWrite) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton.icon(
                        onPressed: state.isSaving ? null : _save,
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(l10n.tOr('saveBranding', 'Save branding')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Center(
              child: Icon(
                Icons.image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  l10n.tOr('settingsLogoError', 'Invalid URL'),
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
