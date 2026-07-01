import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/promotion_entities.dart';
import '../bloc/packages_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/package_dialog.dart';
import '../widgets/promotions_dashboard_widgets.dart';

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
        if (state is PackagesLoading) {
          return const PromotionsDashboardShell(child: LoadingView());
        }
        if (state is PackagesError) {
          return PromotionsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: l10n.t('retry'),
              onRetry: () =>
                  context.read<PackagesBloc>().add(LoadPackagesEvent()),
            ),
          );
        }
        if (state is! PackagesLoaded) return const SizedBox.shrink();

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
                        onPressed: state.isSaving
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
                  if (state.isSaving || state.isRefreshing) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(),
                  ],
                  SizedBox(
                    height: metrics.isMobile
                        ? PromotionsSpace.md
                        : PromotionsSpace.lg,
                  ),
                  DashboardCard(
                    padding: EdgeInsets.zero,
                    child: state.packages.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: metrics.isMobile
                                  ? PromotionsSpace.lg
                                  : PromotionsSpace.xl,
                            ),
                            child: Center(
                              child: Text(
                                l10n.t('noData'),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final table = DataTable(
                                columns: [
                                  DataColumn(label: Text(l10n.t('name'))),
                                  DataColumn(label: Text(l10n.t('promoPrice'))),
                                  DataColumn(
                                    label: Text(l10n.t('promoImpressionCount')),
                                  ),
                                  DataColumn(label: Text(l10n.t('status'))),
                                  DataColumn(label: Text(l10n.t('createdAt'))),
                                  DataColumn(label: Text(l10n.t('actions'))),
                                ],
                                rows: state.packages.map((pkg) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(pkg.name)),
                                      DataCell(
                                          Text(CoinFormat.coins(pkg.priceCoins))),
                                      DataCell(
                                          Text('${pkg.impressionCount}')),
                                      DataCell(
                                        Text(
                                          pkg.isActive
                                              ? l10n.t('active')
                                              : l10n.t('inactive'),
                                        ),
                                      ),
                                      DataCell(
                                          Text(dateFmt.format(pkg.createdAt))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit_outlined,
                                                size: metrics.isMobile ? 16 : 18,
                                              ),
                                              onPressed: state.isSaving
                                                  ? null
                                                  : () => _openDialog(
                                                        context,
                                                        pkg,
                                                      ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                pkg.isActive
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                size: metrics.isMobile ? 16 : 18,
                                              ),
                                              onPressed: state.isSaving
                                                  ? null
                                                  : () => context
                                                      .read<PackagesBloc>()
                                                      .add(
                                                        TogglePackageActiveEvent(
                                                          pkg.id,
                                                          activate:
                                                              !pkg.isActive,
                                                        ),
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );

                              if (metrics.isMobile) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: table,
                                  ),
                                );
                              }
                              return table;
                            },
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
              child: _PackageSearchField(
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

class _PackageSearchField extends StatefulWidget {
  const _PackageSearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
    this.height = 40,
    this.compact = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final double height;
  final bool compact;

  @override
  State<_PackageSearchField> createState() => _PackageSearchFieldState();
}

class _PackageSearchFieldState extends State<_PackageSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_PackageSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: widget.compact ? 12 : null,
            ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: widget.compact ? 12 : 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: widget.compact ? 16 : 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 8,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 10),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
