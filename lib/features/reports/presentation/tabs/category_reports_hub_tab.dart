import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../category_reports/presentation/bloc/category_reports_bloc.dart';
import '../../../category_reports/presentation/widgets/category_reports_table_panel.dart';

class CategoryReportsHubTab extends StatefulWidget {
  const CategoryReportsHubTab({
    super.key,
    this.denseLayout = false,
    this.onCategoryTap,
  });

  final bool denseLayout;
  final ValueChanged<String>? onCategoryTap;

  @override
  State<CategoryReportsHubTab> createState() => _CategoryReportsHubTabState();
}

class _CategoryReportsHubTabState extends State<CategoryReportsHubTab>
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
    return BlocBuilder<CategoryReportsBloc, CategoryReportsState>(
      builder: (context, state) {
        return SizedBox.expand(
          child: switch (state) {
            CategoryReportsInitial() || CategoryReportsLoading() =>
              const Center(child: CircularProgressIndicator()),
            CategoryReportsError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () {
                        final bloc = context.read<CategoryReportsBloc>();
                        bloc
                          ..add(LoadCategoryReportsListEvent(refresh: true))
                          ..add(LoadCategoryReportsOverviewEvent());
                      },
                      child: Text(context.l10n.t('retry')),
                    ),
                  ],
                ),
              ),
            CategoryReportsLoaded() => _buildLoaded(state),
          },
        );
      },
    );
  }

  Widget _buildLoaded(CategoryReportsLoaded state) {
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
            child: CategoryReportsTablePanel(
              state: state,
              searchController: _searchController,
              onRowTap: widget.onCategoryTap,
              hideSearchBar: widget.denseLayout,
              denseLayout: widget.denseLayout,
            ),
          ),
        ],
      ),
    );
  }
}
