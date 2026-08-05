import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/appearance_card.dart';
import '../widgets/privacy_settings_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_stats_grid.dart';
import '../widgets/social_links_card.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const LoadProfile()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, next) {
        if (next is ProfileLoaded && next.message != null) return true;
        if (next is ProfileUpdated) return true;
        if (next is ProfileError) return true;
        return false;
      },
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
          return;
        }
        if (state is ProfileLoaded && state.message != null) {
          final text = state.message == 'profile_updated_successfully'
              ? l10n.tOr(
                  'profile_updated_successfully',
                  'Profile updated successfully',
                )
              : state.message!;
          messenger.showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: state.isError ? scheme.error : null,
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

        return ColoredBox(
          color: scheme.surfaceContainerLowest,
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.topLeft,
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(const LoadProfile());
                  await context.read<ProfileBloc>().stream.firstWhere(
                        (s) => s is ProfileLoaded || s is ProfileError,
                      );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title Header
                      Row(
                        children: [
                          Icon(Icons.person_pin_rounded,
                              color: scheme.primary, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            l10n.tOr('adminProfile', 'Admin Profile'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Content Body
                      if (state is ProfileLoading || state is ProfileInitial)
                        const _ProfileSkeleton()
                      else if (state is ProfileError && profile == null)
                        _ProfileErrorBody(
                          message: state.message,
                          onRetry: () => context
                              .read<ProfileBloc>()
                              .add(const LoadProfile()),
                        )
                      else if (profile != null)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 920;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Hero Header
                                ProfileHeader(
                                  profile: profile,
                                  onEdit: () => _openEdit(context),
                                  onRefresh: () => context
                                      .read<ProfileBloc>()
                                      .add(const LoadProfile()),
                                ),
                                const SizedBox(height: 20),

                                // Stats Grid
                                ProfileStatsGrid(profile: profile),
                                const SizedBox(height: 20),

                                // Responsive Cards Grid / Column
                                if (isWide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Column
                                      Expanded(
                                        child: Column(
                                          children: [
                                            AccountSecurityCard(profile: profile),
                                            const SizedBox(height: 20),
                                            ProfileInfoCard(profile: profile),
                                            const SizedBox(height: 20),
                                            SocialLinksCard(profile: profile),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Right Column
                                      Expanded(
                                        child: Column(
                                          children: [
                                            EngagementMetricsCard(profile: profile),
                                            const SizedBox(height: 20),
                                            ContactLocationCard(profile: profile),
                                            const SizedBox(height: 20),
                                            PrivacySettingsCard(profile: profile),
                                            const SizedBox(height: 20),
                                            AppearanceCard(profile: profile),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      AccountSecurityCard(profile: profile),
                                      const SizedBox(height: 20),
                                      EngagementMetricsCard(profile: profile),
                                      const SizedBox(height: 20),
                                      ProfileInfoCard(profile: profile),
                                      const SizedBox(height: 20),
                                      ContactLocationCard(profile: profile),
                                      const SizedBox(height: 20),
                                      SocialLinksCard(profile: profile),
                                      const SizedBox(height: 20),
                                      PrivacySettingsCard(profile: profile),
                                      const SizedBox(height: 20),
                                      AppearanceCard(profile: profile),
                                    ],
                                  ),
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
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const EditProfilePage(),
        ),
      ),
    );
    if (context.mounted) {
      bloc.add(const LoadProfile());
    }
  }

  ProfileEntity? _profileOf(ProfileState state) {
    return switch (state) {
      ProfileLoaded(:final profile) => profile,
      ProfileUpdating(:final profile) => profile,
      ProfileUploadingAvatar(:final profile) => profile,
      ProfileUpdated(:final profile) => profile,
      ProfileError(:final profile) => profile,
      _ => null,
    };
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Skeleton
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 24),
        // Stats Row Skeleton
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Card Skeletons
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorBody extends StatelessWidget {
  const _ProfileErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.tOr('retry', 'Retry Loading Profile')),
            ),
          ],
        ),
      ),
    );
  }
}
