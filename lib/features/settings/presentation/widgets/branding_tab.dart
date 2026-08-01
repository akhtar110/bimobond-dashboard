import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/settings_admin_entities.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_logo_picker.dart';

/// Branding form with logo preview, computer upload, and save action.
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
  Uint8List? _localLogoBytes;

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
    _localLogoBytes = null;
  }

  void _applyLogoUrl(String? logoUrl) {
    final next = logoUrl ?? '';
    if (_logoUrlController.text == next) return;
    _logoUrlController.text = next;
    _localLogoBytes = null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final rawLogo = _logoUrlController.text.trim();
    final logoUrl = rawLogo.isEmpty
        ? null
        : (resolveMediaUrl(
              rawLogo.startsWith('/') || rawLogo.startsWith('http')
                  ? rawLogo
                  : '/$rawLogo',
            ) ??
            rawLogo);
    context.read<AdminSettingsBloc>().add(
          UpdateAdminBrandingEvent(
            appName: _appNameController.text.trim(),
            tagline: _taglineController.text.trim().isEmpty
                ? null
                : _taglineController.text.trim(),
            supportEmail: _supportEmailController.text.trim().isEmpty
                ? null
                : _supportEmailController.text.trim(),
            logoUrl: logoUrl,
          ),
        );
  }

  Future<void> _pickAndUploadLogo() async {
    final picked = await pickBrandingLogoFile();
    if (picked == null || !mounted) return;

    setState(() => _localLogoBytes = picked.bytes);
    context.read<AdminSettingsBloc>().add(
          UploadAdminBrandingLogoEvent(
            bytes: picked.bytes,
            filename: picked.name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canWrite = PermissionManager.canWriteSettings(context);

    return BlocConsumer<AdminSettingsBloc, AdminSettingsState>(
      listenWhen: (prev, next) =>
          prev.branding?.id != next.branding?.id ||
          prev.branding?.logoUrl != next.branding?.logoUrl,
      listener: (context, state) {
        final branding = state.branding;
        if (branding == null) return;
        if (_loadedId != branding.id) {
          _syncFromBranding(branding);
          return;
        }
        _applyLogoUrl(branding.logoUrl);
        if (mounted) setState(() {});
      },
      builder: (context, state) {
        _syncFromBranding(state.branding);

        final logoUrl = _logoUrlController.text.trim();

        final fieldDecoration = InputDecoration(
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        );

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.tOr('tabBranding', 'Branding'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tOr(
                  'settingsBrandingDescription',
                  'Update application name, tagline, support contact and logo.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final fields = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _appNameController,
                        enabled: canWrite && !state.isSaving,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.tOr(
                                'settingsAppNameRequired',
                                'App name is required',
                              )
                            : null,
                        decoration: fieldDecoration.copyWith(
                          labelText: l10n.tOr('settingsAppName', 'App name'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _taglineController,
                        enabled: canWrite && !state.isSaving,
                        decoration: fieldDecoration.copyWith(
                          labelText: l10n.tOr('settingsTagline', 'Tagline'),
                        ),
                      ),
                    ],
                  );

                  final logoPicker = _LogoPicker(
                    url: logoUrl,
                    localBytes: _localLogoBytes,
                    canWrite: canWrite,
                    isUploading: state.isSaving,
                    onPick: _pickAndUploadLogo,
                    onClear: canWrite
                        ? () => setState(() {
                              _logoUrlController.clear();
                              _localLogoBytes = null;
                            })
                        : null,
                  );

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: logoPicker,
                        ),
                        const SizedBox(height: 14),
                        fields,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      logoPicker,
                      const SizedBox(width: 16),
                      Expanded(child: fields),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final emailField = TextFormField(
                    controller: _supportEmailController,
                    enabled: canWrite && !state.isSaving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: fieldDecoration.copyWith(
                      labelText:
                          l10n.tOr('settingsSupportEmail', 'Support email'),
                    ),
                  );
                  final logoField = TextFormField(
                    controller: _logoUrlController,
                    enabled: canWrite && !state.isSaving,
                    onChanged: (_) => setState(() => _localLogoBytes = null),
                    decoration: fieldDecoration.copyWith(
                      labelText: l10n.tOr('settingsLogoUrl', 'Logo URL'),
                      helperText: l10n.tOr(
                        'settingsLogoUrlHelper',
                        'Upload from your computer or paste a public image URL.',
                      ),
                    ),
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        emailField,
                        const SizedBox(height: 12),
                        logoField,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: emailField),
                      const SizedBox(width: 12),
                      Expanded(child: logoField),
                    ],
                  );
                },
              ),
              if (canWrite) ...[
                const SizedBox(height: 18),
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
        );
      },
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.url,
    required this.localBytes,
    required this.canWrite,
    required this.isUploading,
    required this.onPick,
    this.onClear,
  });

  final String url;
  final Uint8List? localBytes;
  final bool canWrite;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasImage =
        (localBytes != null && localBytes!.isNotEmpty) || url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: canWrite && !isUploading ? onPick : null,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (localBytes != null && localBytes!.isNotEmpty)
                      Image.memory(localBytes!, fit: BoxFit.cover)
                    else if (url.isNotEmpty)
                      Image.network(
                        resolveMediaUrl(
                              url.startsWith('/') || url.startsWith('http')
                                  ? url
                                  : '/$url',
                            ) ??
                            url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            l10n.tOr('settingsLogoError', 'Invalid URL'),
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: scheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                    if (isUploading)
                      ColoredBox(
                        color: scheme.scrim.withValues(alpha: 0.35),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      )
                    else if (canWrite)
                      Align(
                        alignment: AlignmentDirectional.bottomCenter,
                        child: ColoredBox(
                          color: scheme.scrim.withValues(alpha: 0.45),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_rounded,
                                  size: 14,
                                  color: scheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.tOr('uploadImage', 'Upload image'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tOr(
            'settingsLogoUploadHint',
            'Click to attach a logo from your computer.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        if (canWrite && hasImage && onClear != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: isUploading ? null : onClear,
            child: Text(l10n.tOr('clear', 'Clear')),
          ),
        ],
      ],
    );
  }
}
