import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/promotion_entities.dart';
import '../bloc/packages_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/package_dialog.dart';
import '../widgets/packages_table.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_data_display_widgets.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<PackagesBloc, PackagesState>(
      listener: (context, state) {
        if (state is PackagesLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor:
                  state.isError ? Theme.of(context).colorScheme.error : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PackagesLoading;
        final isInitial = state is PackagesInitial;
        final errorMessage = switch (state) {
          PackagesError(:final message) => message,
          _ => null,
        };
        final loaded = state is PackagesLoaded ? state : null;
        final showProgress = isLoading ||
            isInitial ||
            (loaded != null && (loaded.isSaving || loaded.isRefreshing));
        final isEmpty = loaded != null && loaded.packages.isEmpty;
        final dateFmt = DateFormat.yMMMd();

        return PromotionsDashboardShell(
          child: Builder(
            builder: (context) {
              final metrics = promotionsMetricsOf(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.t('promoPackagesTitle'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: metrics.isMobile ? 20 : null,
                              ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: loaded?.isSaving == true
                            ? null
                            : () => _openDialog(context, null),
                        icon: Icon(
                          Icons.add,
                          size: metrics.isMobile ? 18 : 24,
                        ),
                        label: metrics.isMobile
                            ? const SizedBox.shrink()
                            : Text(l10n.t('create')),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            metrics.isMobile ? 44 : 120,
                            metrics.isMobile ? 40 : 44,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.isMobile ? 0 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.sectionGap),
                  const _PackagesSearchBar(),
                  if (showProgress) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(
                    height: metrics.isMobile
                        ? PromotionsSpace.md
                        : PromotionsSpace.lg,
                  ),
                  PromotionsDataSection(
                    child: PromotionsDataBody(
                      isLoading: isLoading || isInitial,
                      errorMessage: errorMessage,
                      onRetry: () =>
                          context.read<PackagesBloc>().add(LoadPackagesEvent()),
                      isEmpty: isEmpty,
                      emptyMessage: l10n.t('noData'),
                      child: loaded == null
                          ? const SizedBox.shrink()
                          : PackagesTable(
                              packages: loaded.packages,
                              dateFmt: dateFmt,
                              isSaving: loaded.isSaving,
                              onEdit: (pkg) => _openDialog(context, pkg),
                              onToggleActive: (pkg, {required activate}) =>
                                  context.read<PackagesBloc>().add(
                                        TogglePackageActiveEvent(
                                          pkg.id,
                                          activate: activate,
                                        ),
                                      ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    PromotionPackageEntity? existing,
  ) async {
    final data = await showPackageDialog(context, existing: existing);
    if (data == null || !context.mounted) return;
    final bloc = context.read<PackagesBloc>();
    if (existing == null) {
      bloc.add(CreatePackageEvent(data.createData));
    } else {
      bloc.add(UpdatePackageEvent(existing.id, data.updateData));
    }
  }
}

class _PackagesSearchBar extends StatelessWidget {
  const _PackagesSearchBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final metrics = promotionsMetricsOf(context);

    return BlocSelector<PackagesBloc, PackagesState, String>(
      selector: (state) => state is PackagesLoaded ? state.search : '',
      builder: (context, search) {
        final hasSearch = search.trim().isNotEmpty;

        return Row(
          children: [
            Expanded(
              child: PromotionsToolbarSearchField(
                hint: l10n.t('promoSearchPackages'),
                initialValue: search,
                height: metrics.filterControlHeight,
                compact: metrics.isMobile,
                onChanged: (q) => context
                    .read<PackagesBloc>()
                    .add(SearchPackagesEvent(q)),
              ),
            ),
            if (hasSearch) ...[
              SizedBox(width: metrics.toolbarFilterGap),
              IconButton(
                tooltip: l10n.t('clearFilters'),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    context.read<PackagesBloc>().add(ClearPackageSearchEvent()),
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: metrics.isMobile ? 16 : 18,
                  color: scheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
