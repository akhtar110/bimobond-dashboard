import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gift_reports/presentation/bloc/gift_reports_bloc.dart';
import '../../../gift_reports/presentation/widgets/gift_reports_table_panel.dart';

class GiftReportsHubTab extends StatefulWidget {
  const GiftReportsHubTab({
    super.key,
    this.denseLayout = false,
    this.onGiftTap,
  });

  final bool denseLayout;
  final ValueChanged<String>? onGiftTap;

  @override
  State<GiftReportsHubTab> createState() => _GiftReportsHubTabState();
}

class _GiftReportsHubTabState extends State<GiftReportsHubTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<GiftReportsBloc, GiftReportsState>(
      builder: (context, state) {
        return SizedBox.expand(
          child: switch (state) {
            GiftReportsInitial() || GiftReportsLoading() =>
              const Center(child: CircularProgressIndicator()),
            GiftReportsError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => context
                          .read<GiftReportsBloc>()
                          .add(LoadGiftReportsListEvent(refresh: true)),
                      child: Text(context.l10n.t('retry')),
                    ),
                  ],
                ),
              ),
            GiftReportsLoaded() => _buildLoaded(state),
          },
        );
      },
    );
  }

  Widget _buildLoaded(GiftReportsLoaded state) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        widget.denseLayout ? 0 : 12,
        widget.denseLayout ? 0 : 8,
        widget.denseLayout ? 0 : 12,
        widget.denseLayout ? 0 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GiftReportsTablePanel(
              state: state,
              searchController: _searchController,
              onRowTap: widget.onGiftTap,
              hideSearchBar: widget.denseLayout,
              denseLayout: widget.denseLayout,
            ),
          ),
        ],
      ),
    );
  }
}
