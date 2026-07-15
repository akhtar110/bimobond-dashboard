import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../../users/presentation/widgets/permission_denied_state.dart';
import '../bloc/user_interests_bloc.dart';
import '../bloc/user_interests_event.dart';
import '../bloc/user_interests_state.dart';
import '../utils/user_interests_responsive.dart';
import 'user_interests_filters_bar.dart';
import 'user_interests_overview_cards.dart';
import 'user_interests_topics_list.dart';

/// Embedded topics & interests panel for user detail tab.
class UserInterestsPanel extends StatefulWidget {
  const UserInterestsPanel({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  final String userId;
  final bool embedded;

  @override
  State<UserInterestsPanel> createState() => _UserInterestsPanelState();
}

class _UserInterestsPanelState extends State<UserInterestsPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<UserInterestsBloc>()
          .add(LoadUserInterestsEvent(widget.userId));
    });
  }

  @override
  void didUpdateWidget(UserInterestsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      context
          .read<UserInterestsBloc>()
          .add(LoadUserInterestsEvent(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = UserInterestsLayoutMetrics(
          getUserInterestsDeviceType(constraints.maxWidth),
        );

        return BlocBuilder<UserInterestsBloc, UserInterestsState>(
          builder: (context, state) {
            final isRefreshing =
                state is UserInterestsLoaded && state.isRefreshing;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.embedded) ...[
                  Text(
                    context.l10n.tOr(
                      'userInterestTopicsAndInterests',
                      'Topics & Interests',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: PromotionsSpace.lg),
                ],
                _OverviewStrip(state: state, metrics: metrics),
                SizedBox(height: metrics.sectionGap),
                UserInterestsFiltersBar(metrics: metrics),
                if (state is UserInterestsLoading || isRefreshing) ...[
                  const SizedBox(height: PromotionsSpace.sm),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                SizedBox(height: metrics.sectionGap),
                Expanded(
                  child: _Body(state: state, userId: widget.userId),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({
    required this.state,
    required this.metrics,
  });

  final UserInterestsState state;
  final UserInterestsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (state is UserInterestsLoaded) {
      return UserInterestsOverviewCards(
        meta: (state as UserInterestsLoaded).meta,
        metrics: metrics,
      );
    }
    if (state is UserInterestsEmpty) {
      return UserInterestsOverviewCards(
        meta: (state as UserInterestsEmpty).meta,
        metrics: metrics,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.userId,
  });

  final UserInterestsState state;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state is UserInterestsError) {
      final error = state as UserInterestsError;
      if (error.isForbidden) {
        return PermissionDeniedState(
          message: l10n.tOr(
            'userInterestForbidden',
            'You are not allowed to view user interests.',
          ),
          onRetry: () => context
              .read<UserInterestsBloc>()
              .add(LoadUserInterestsEvent(userId)),
        );
      }
      return ErrorView(
        message: error.isNotFound
            ? l10n.tOr('userInterestUserNotFound', 'User not found.')
            : (error.message.isNotEmpty
                ? error.message
                : l10n.tOr(
                    'userInterestFailedToLoad',
                    'Failed to load topics.',
                  )),
        retryLabel: l10n.t('retry'),
        onRetry: () => context
            .read<UserInterestsBloc>()
            .add(LoadUserInterestsEvent(userId)),
      );
    }

    if (state is UserInterestsInitial || state is UserInterestsLoading) {
      return const LoadingView();
    }

    if (state is UserInterestsEmpty) {
      return Center(
        child: Text(
          l10n.tOr('userInterestNoTopicsFound', 'No topics found'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final loaded = state as UserInterestsLoaded;
    return UserInterestsTopicsList(
      interests: loaded.filteredInterests,
      notInterests: loaded.filteredNotInterests,
    );
  }
}
