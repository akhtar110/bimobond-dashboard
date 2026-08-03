import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/update_profile_data.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/avatar_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _youtubeCtrl;

  DateTime? _dateOfBirth;
  bool _isPrivate = false;
  bool _allowComments = true;
  bool _allowDirectMsgs = true;
  String _messagePermission = 'EVERYONE';
  String _language = 'en';
  String _theme = 'system';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _fullNameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _genderCtrl = TextEditingController();
    _countryCtrl = TextEditingController();
    _regionCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _instagramCtrl = TextEditingController();
    _youtubeCtrl = TextEditingController();
  }

  void _hydrate(ProfileEntity profile) {
    if (_initialized) return;
    _initialized = true;
    _usernameCtrl.text = profile.username;
    _fullNameCtrl.text = profile.fullName ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _phoneCtrl.text = profile.phoneNumber ?? '';
    _genderCtrl.text = profile.gender ?? '';
    _countryCtrl.text = profile.country ?? '';
    _regionCtrl.text = profile.region ?? '';
    _cityCtrl.text = profile.city ?? '';
    _instagramCtrl.text = profile.instagramUrl ?? '';
    _youtubeCtrl.text = profile.youtubeUrl ?? '';
    _dateOfBirth = profile.dateOfBirth;
    _isPrivate = profile.isPrivate;
    _allowComments = profile.allowComments;
    _allowDirectMsgs = profile.allowDirectMsgs;
    _messagePermission = profile.messagePermission.toUpperCase();
    _language = profile.language.toLowerCase();
    _theme = profile.theme.toLowerCase();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _cityCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  ProfileEntity? _profileOf(ProfileState state) {
    return switch (state) {
      ProfileLoaded(:final effectiveProfile) => effectiveProfile,
      ProfileUpdating(:final effectiveProfile) => effectiveProfile,
      ProfileUploadingAvatar(:final effectiveProfile) => effectiveProfile,
      ProfileUpdated(:final profile) => profile,
      ProfileError(:final profile) => profile,
      _ => null,
    };
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = UpdateProfileData(
      username: _usernameCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      dateOfBirth: _dateOfBirth,
      isPrivate: _isPrivate,
      allowComments: _allowComments,
      allowDirectMsgs: _allowDirectMsgs,
      messagePermission: _messagePermission,
      language: _language,
      theme: _theme,
      phoneNumber: _phoneCtrl.text.trim(),
      gender: _genderCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim(),
      youtubeUrl: _youtubeCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );

    context.read<ProfileBloc>().add(UpdateProfile(data));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) =>
          c is ProfileUpdated ||
          (c is ProfileLoaded && c.message != null) ||
          c is ProfileError,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is ProfileUpdated) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.tOr(
                  'profile_updated_successfully',
                  'Profile updated successfully',
                ),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.of(context).pop(true);
          return;
        }
        if (state is ProfileLoaded && state.message != null && state.isError) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: scheme.error,
            ),
          );
          context.read<ProfileBloc>().add(const ClearProfileFeedback());
          return;
        }
        if (state is ProfileError) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final profile = _profileOf(state);
        if (profile != null) _hydrate(profile);

        final busy =
            state is ProfileUpdating || state is ProfileUploadingAvatar;

        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: AppBar(
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tOr('edit_profile', 'Edit Profile'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  l10n.tOr(
                    'edit_profile_subtitle',
                    'Update account info, location & preferences',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 20),
                child: FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    l10n.tOr('save_changes', 'Save Changes'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: profile == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox.expand(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeroAvatarCard(
                                profile: profile,
                                uploading: state is ProfileUploadingAvatar,
                                onPicked: (name, bytes) {
                                  context.read<ProfileBloc>().add(
                                        UploadAvatar(
                                          bytes: Uint8List.fromList(bytes),
                                          filename: name,
                                        ),
                                      );
                                },
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 820;

                                  final personalInfoSection = SettingsSection(
                                    title: l10n.tOr(
                                      'personalInformation',
                                      'Personal Information',
                                    ),
                                    child: SettingsSurfaceCard(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _usernameCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr(
                                                  'username', 'Username'),
                                              icon: Icons.alternate_email_rounded,
                                            ),
                                            validator: (v) {
                                              final value = v?.trim() ?? '';
                                              if (value.isEmpty) {
                                                return l10n.tOr(
                                                  'usernameRequired',
                                                  'Username is required',
                                                );
                                              }
                                              if (!UpdateProfileData
                                                  .usernamePattern
                                                  .hasMatch(value)) {
                                                return l10n.tOr(
                                                  'usernameInvalid',
                                                  '3–20 chars: letters, numbers, underscore',
                                                );
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _fullNameCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr(
                                                  'full_name', 'Full name'),
                                              icon: Icons.badge_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _bioCtrl,
                                            maxLines: 3,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('bio', 'Bio'),
                                              icon: Icons.notes_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _genderCtrl,
                                            decoration: _dec(
                                              context,
                                              label:
                                                  l10n.tOr('gender', 'Gender'),
                                              icon: Icons.wc_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          InkWell(
                                            onTap: _pickDob,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: InputDecorator(
                                              decoration: _dec(
                                                context,
                                                label: l10n.tOr(
                                                  'date_of_birth',
                                                  'Date of birth',
                                                ),
                                                icon: Icons.calendar_today_outlined,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _dateOfBirth != null
                                                          ? DateFormat.yMMMd()
                                                              .format(
                                                                  _dateOfBirth!)
                                                          : l10n.tOr(
                                                              'notSet',
                                                              'Not set',
                                                            ),
                                                      style: theme.textTheme
                                                          .bodyMedium?.copyWith(
                                                        fontWeight:
                                                            _dateOfBirth != null
                                                                ? FontWeight.w600
                                                                : FontWeight.w400,
                                                        color: _dateOfBirth != null
                                                            ? scheme.onSurface
                                                            : scheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_dateOfBirth != null)
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.close_rounded,
                                                          size: 18),
                                                      onPressed: () => setState(
                                                        () => _dateOfBirth = null,
                                                      ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  final contactLocationSection = SettingsSection(
                                    title: l10n.tOr(
                                      'contactAndLocation',
                                      'Contact & Location',
                                    ),
                                    child: SettingsSurfaceCard(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _phoneCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr(
                                                  'phone_number', 'Phone number'),
                                              icon: Icons.phone_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _countryCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('country', 'Country'),
                                              icon: Icons.public_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _regionCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('region', 'Region'),
                                              icon: Icons.map_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _cityCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('city', 'City'),
                                              icon: Icons.location_city_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  final socialLinksSection = SettingsSection(
                                    title:
                                        l10n.tOr('socialLinks', 'Social Links'),
                                    child: SettingsSurfaceCard(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _instagramCtrl,
                                            decoration: _dec(
                                              context,
                                              label:
                                                  l10n.tOr('instagram', 'Instagram'),
                                              icon: Icons.camera_alt_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _youtubeCtrl,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('youtube', 'YouTube'),
                                              icon: Icons.play_circle_outline_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  final privacySection = SettingsSection(
                                    title: l10n.tOr('privacy', 'Privacy'),
                                    child: SettingsSurfaceCard(
                                      child: Column(
                                        children: [
                                          SwitchListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            secondary: Icon(
                                              Icons.lock_outline_rounded,
                                              size: 20,
                                              color: scheme.primary,
                                            ),
                                            title: Text(
                                              l10n.tOr(
                                                'private_account',
                                                'Private Account',
                                              ),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              l10n.tOr(
                                                'privateAccountHint',
                                                'Only approved followers can see your profile',
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            value: _isPrivate,
                                            onChanged: busy
                                                ? null
                                                : (v) => setState(
                                                    () => _isPrivate = v),
                                          ),
                                          const Divider(height: 16),
                                          SwitchListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            secondary: Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 20,
                                              color: scheme.primary,
                                            ),
                                            title: Text(
                                              l10n.tOr(
                                                'allowComments',
                                                'Allow Comments',
                                              ),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              l10n.tOr(
                                                'allowCommentsHint',
                                                'Allow users to comment on your posts',
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            value: _allowComments,
                                            onChanged: busy
                                                ? null
                                                : (v) => setState(
                                                      () => _allowComments = v,
                                                    ),
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            // ignore: deprecated_member_use
                                            value: _messagePermission,
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr(
                                                'message_permission',
                                                'Message Permission',
                                              ),
                                              icon: Icons.mark_chat_unread_outlined,
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'EVERYONE',
                                                child: Text(
                                                  l10n.tOr(
                                                      'everyone', 'Everyone'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'FOLLOWERS',
                                                child: Text(
                                                  l10n.tOr(
                                                      'followers', 'Followers'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'FRIENDS',
                                                child: Text(
                                                  l10n.tOr('friends', 'Friends'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'NOBODY',
                                                child: Text(
                                                  l10n.tOr('nobody', 'Nobody'),
                                                ),
                                              ),
                                            ],
                                            onChanged: busy
                                                ? null
                                                : (v) {
                                                    if (v == null) return;
                                                    setState(
                                                      () =>
                                                          _messagePermission = v,
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  final appearanceSection = SettingsSection(
                                    title: l10n.tOr('appearance', 'Appearance'),
                                    child: SettingsSurfaceCard(
                                      child: Column(
                                        children: [
                                          DropdownButtonFormField<String>(
                                            // ignore: deprecated_member_use
                                            value: _language == 'ar' ? 'ar' : 'en',
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('language', 'Language'),
                                              icon: Icons.translate_rounded,
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'en',
                                                child: Text(
                                                  l10n.tOr('english', 'English'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'ar',
                                                child: Text(
                                                  l10n.tOr('arabic', 'Arabic'),
                                                ),
                                              ),
                                            ],
                                            onChanged: busy
                                                ? null
                                                : (v) {
                                                    if (v == null) return;
                                                    setState(
                                                        () => _language = v);
                                                  },
                                          ),
                                          const SizedBox(height: 14),
                                          DropdownButtonFormField<String>(
                                            // ignore: deprecated_member_use
                                            value: switch (_theme) {
                                              'dark' => 'dark',
                                              'light' => 'light',
                                              _ => 'system',
                                            },
                                            decoration: _dec(
                                              context,
                                              label: l10n.tOr('theme', 'Theme'),
                                              icon: Icons.palette_outlined,
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'system',
                                                child: Text(
                                                  l10n.tOr('system', 'System'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'light',
                                                child: Text(
                                                  l10n.tOr('light', 'Light'),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'dark',
                                                child: Text(
                                                  l10n.tOr('dark', 'Dark'),
                                                ),
                                              ),
                                            ],
                                            onChanged: busy
                                                ? null
                                                : (v) {
                                                    if (v == null) return;
                                                    setState(() => _theme = v);
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              personalInfoSection,
                                              const SizedBox(height: 24),
                                              socialLinksSection,
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              contactLocationSection,
                                              const SizedBox(height: 24),
                                              privacySection,
                                              const SizedBox(height: 24),
                                              appearanceSection,
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      personalInfoSection,
                                      const SizedBox(height: 24),
                                      contactLocationSection,
                                      const SizedBox(height: 24),
                                      socialLinksSection,
                                      const SizedBox(height: 24),
                                      privacySection,
                                      const SizedBox(height: 24),
                                      appearanceSection,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  InputDecoration _dec(
    BuildContext context, {
    required String label,
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: scheme.primary.withValues(alpha: 0.75))
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.8),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}

class _HeroAvatarCard extends StatelessWidget {
  const _HeroAvatarCard({
    required this.profile,
    required this.uploading,
    required this.onPicked,
  });

  final ProfileEntity profile;
  final bool uploading;
  final Function(String name, List<int> bytes) onPicked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final displayName = profile.fullName?.trim().isNotEmpty == true
        ? profile.fullName!
        : profile.username;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AvatarPicker(
              profile: profile,
              uploading: uploading,
              onPicked: onPicked,
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@${profile.username}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

