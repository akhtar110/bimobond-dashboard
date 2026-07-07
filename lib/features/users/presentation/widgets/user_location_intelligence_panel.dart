import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/bloc/location_intelligence_bloc.dart';
import '../../../promotions/presentation/utils/location_responsive.dart';
import '../../../promotions/presentation/widgets/location_intelligence_widgets.dart';
import '../../domain/entities/user_entity.dart';

/// Reusable location intelligence UI for the admin dashboard and user detail.
class UserLocationIntelligencePanel extends StatefulWidget {
  const UserLocationIntelligencePanel({
    super.key,
    this.fixedUser,
    this.embedded = false,
    this.enableMapZoomControls = false,
    this.mapMinZoom = 2,
    this.showLimitFilter = false,
  });

  /// When set, loads and locks the panel to this user's location trail.
  final UserEntity? fixedUser;

  /// Compact layout for tabs inside [UserDetailScreen].
  final bool embedded;

  /// Shows +/- zoom controls on the map (user locations admin page).
  final bool enableMapZoomControls;

  /// Lowest zoom level allowed when [enableMapZoomControls] is true.
  final double mapMinZoom;

  /// Hides the 25/50/100 limit dropdown (off on the admin user locations page).
  final bool showLimitFilter;

  @override
  State<UserLocationIntelligencePanel> createState() =>
      _UserLocationIntelligencePanelState();
}

class _UserLocationIntelligencePanelState
    extends State<UserLocationIntelligencePanel> {
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(UserLocationIntelligencePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedUser?.id != widget.fixedUser?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    super.dispose();
  }

  void _onListScroll() {
    if (!mounted || !_listScrollController.hasClients) return;

    final width = MediaQuery.sizeOf(context).width;
    final metrics = LocationLayoutMetrics(getLocationDeviceType(width));
    if (!metrics.useInfiniteScroll) return;

    final position = _listScrollController.position;
    if (position.pixels < position.maxScrollExtent - 300) return;

    final bloc = context.read<LocationIntelligenceBloc>();
    final state = bloc.state;
    if (state is! LocationIntelligenceLoaded) return;

    if (state.isUserDetail) {
      bloc.add(LoadMoreLocationHistoryEvent());
    } else {
      bloc.add(LoadMoreLocationOverviewEvent());
    }
  }

  void _bootstrap() {
    if (!mounted) return;
    final bloc = context.read<LocationIntelligenceBloc>();
    final fixedUser = widget.fixedUser;

    if (fixedUser != null) {
      final loaded = bloc.state;
      if (loaded is LocationIntelligenceLoaded &&
          loaded.selectedUser?.id == fixedUser.id) {
        return;
      }
      bloc.add(SelectLocationUserEvent(fixedUser));
      return;
    }

    if (bloc.state is LocationIntelligenceInitial) {
      bloc.add(LoadLocationOverviewEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = LocationLayoutMetrics(
          getLocationDeviceType(constraints.maxWidth),
        );

        return BlocBuilder<LocationIntelligenceBloc, LocationIntelligenceState>(
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType ||
              (previous is LocationIntelligenceLoaded &&
                  current is LocationIntelligenceLoaded &&
                  (previous.isUserDetail != current.isUserDetail ||
                      previous.selectedUser?.id !=
                          current.selectedUser?.id)),
          builder: (context, state) {
            final loaded = switch (state) {
              LocationIntelligenceLoaded s => s,
              _ => null,
            };
            final isLoading = state is LocationIntelligenceLoading;
            final isUserDetail =
                widget.fixedUser != null || loaded?.isUserDetail == true;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.embedded) ...[
                  LocationHeaderSection(
                    isUserDetail: isUserDetail,
                    metrics: metrics,
                    compact: !widget.showLimitFilter,
                  ),
                  SizedBox(
                    height: widget.showLimitFilter
                        ? metrics.sectionGap
                        : metrics.toolbarSectionGap,
                  ),
                  LocationToolbar(
                    state: state,
                    fixedUser: widget.fixedUser,
                    metrics: metrics,
                    showLimitFilter: widget.showLimitFilter,
                  ),
                ],
                if (isLoading) ...[
                  SizedBox(height: metrics.toolbarFilterGap),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                SizedBox(height: metrics.toolbarSectionGap),
                Expanded(
                  child: LocationContentSection(
                    state: state,
                    singleUserOnly: widget.fixedUser != null,
                    fixedUser: widget.fixedUser,
                    mapMinZoom: widget.mapMinZoom,
                    showZoomControls: widget.enableMapZoomControls,
                    metrics: metrics,
                    listScrollController: _listScrollController,
                  ),
                ),
              ],
            );

            if (widget.embedded) {
              return content;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding,
                metrics.pageHorizontalPadding,
                metrics.pageBottomPadding,
              ),
              child: content,
            );
          },
        );
      },
    );
  }
}
