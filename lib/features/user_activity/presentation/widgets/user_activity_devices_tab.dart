import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../bloc/user_activity_bloc.dart';
import 'activity_empty_state.dart';
import 'last_active_history_dialog.dart';
import 'user_activity_shimmer.dart';
import 'user_device_card.dart';

class UserActivityDevicesTab extends StatefulWidget {
  const UserActivityDevicesTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityDevicesTab> createState() => _UserActivityDevicesTabState();
}

class _UserActivityDevicesTabState extends State<UserActivityDevicesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserActivityBloc>();
    if (!bloc.state.devicesLoaded) {
      bloc.add(LoadDevices());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final bloc = context.read<UserActivityBloc>();
    final state = bloc.state;
    if (state.devicesHasReachedMax || state.devicesLoadingMore) return;
    bloc.add(LoadMoreDevices());
  }

  void _openLastActiveHistory(String userId) {
    if (userId.isEmpty) return;
    showLastActiveHistoryDialog(context, userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserActivityBloc, UserActivityState>(
      builder: (context, state) {
        if (state.devicesLoading && state.devices.isEmpty) {
          return UserActivityListShimmer(isDark: widget.isDark);
        }

        if (state.devicesError != null && state.devices.isEmpty) {
          return Center(child: Text(state.devicesError!));
        }

        if (state.devices.isEmpty) {
          return Column(
            children: [
              _HistoryActionBar(
                enabled: state.userId.isNotEmpty,
                onPressed: () => _openLastActiveHistory(state.userId),
              ),
              Expanded(
                child: ActivityEmptyState(
                  icon: Icons.devices_outlined,
                  message: l10n.t('noDevicesFound'),
                  isDark: widget.isDark,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _HistoryActionBar(
              enabled: state.userId.isNotEmpty,
              onPressed: () => _openLastActiveHistory(state.userId),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount:
                    state.devices.length + (state.devicesLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.devices.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return UserDeviceCard(
                    device: state.devices[index],
                    isDark: widget.isDark,
                    onViewLastActiveHistory: state.userId.isEmpty
                        ? null
                        : () => _openLastActiveHistory(state.userId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryActionBar extends StatelessWidget {
  const _HistoryActionBar({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(
            Icons.history_rounded,
            size: 18,
            color: enabled ? scheme.primary : scheme.onSurfaceVariant,
          ),
          label: Text(
            l10n.tOr('viewLastActiveHistory', 'Last active history'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: enabled ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
