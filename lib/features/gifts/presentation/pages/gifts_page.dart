import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../bloc/gifts_bloc.dart';
import '../widgets/gift_card.dart';

/// Responsive column count for admin catalog grids.
int adminGridColumnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 500) return 2;
  return 1;
}

class GiftsPage extends StatefulWidget {
  const GiftsPage({super.key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  @override
  void initState() {
    super.initState();
    context.read<GiftsBloc>().add(LoadAdminGiftsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FC),
      floatingActionButton: BlocBuilder<GiftsBloc, GiftsState>(
        builder: (context, state) {
          if (state is! GiftsLoaded) return const SizedBox.shrink();
          final l10n = context.l10n;
          return FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.t('addGift')),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          );
        },
      ),
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (context, state) {
          if (state is GiftsLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _SliverHeader(theme: theme, isDark: isDark, state: state),
              if (state is GiftsLoaded) ...[
                _SliverFilters(loaded: state, theme: theme),
                _SliverGrid(loaded: state),
              ] else if (state is GiftsLoading) ...[
                const _SliverSkeletons(),
              ] else if (state is GiftsError) ...[
                _SliverError(message: state.message),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
            ],
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final thumbCtrl = TextEditingController();
    final animCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('createNewGift')),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Gift Name *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: thumbCtrl,
                  decoration: InputDecoration(
                    labelText: 'Thumbnail URL *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: animCtrl,
                  decoration: InputDecoration(
                    labelText: 'Animation URL (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (USD) *',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return l10n.t('requiredField');
                    if (double.tryParse(v!.trim()) == null) {
                      return l10n.t('requiredField');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              context.read<GiftsBloc>().add(CreateGiftEvent(
                    CreateGiftData(
                      name: nameCtrl.text.trim(),
                      thumbnailUrl: thumbCtrl.text.trim(),
                      animationUrl: animCtrl.text.trim().isEmpty
                          ? null
                          : animCtrl.text.trim(),
                      priceUsd: double.parse(priceCtrl.text.trim()),
                    ),
                  ));
            },
            child: Text(l10n.t('createGift')),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({
    required this.theme,
    required this.isDark,
    required this.state,
  });

  final ThemeData theme;
  final bool isDark;
  final GiftsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);
    final isLoading = state is GiftsLoading;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('gifts'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage virtual gift catalog for auctions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () => context
                                .read<GiftsBloc>()
                                .add(LoadAdminGiftsEvent()),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xFF4B5563),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : const Color(0xFF4B5563),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: dividerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────────────────────

class _SliverFilters extends StatelessWidget {
  const _SliverFilters({required this.loaded, required this.theme});

  final GiftsLoaded loaded;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final metaColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Text(
                  '${loaded.displayed.length} ${l10n.t('gifts').toLowerCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: metaColor,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: FilterChip(
                    label: Text(
                      l10n.t('showInactiveOnly'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: loaded.showInactiveOnly,
                    onSelected: (v) {
                      context.read<GiftsBloc>().add(ToggleGiftsFilterEvent(v));
                    },
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: loaded.showInactiveOnly
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _SliverGrid extends StatelessWidget {
  const _SliverGrid({required this.loaded});
  final GiftsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final gifts = loaded.displayed;

    if (gifts.isEmpty) {
      return const _SliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        final rowCount = (gifts.length / columns).ceil();
        const gap = 12.0;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final start = rowIndex * columns;
                final end = (start + columns).clamp(0, gifts.length);
                final rowGifts = gifts.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? gap : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: i < rowGifts.length
                                ? GiftCard(
                                    gift: rowGifts[i],
                                    onEdit: () => _showEditDialog(
                                      context,
                                      rowGifts[i].id,
                                      rowGifts[i].name,
                                      rowGifts[i].thumbnailUrl,
                                      rowGifts[i].animationUrl,
                                      rowGifts[i].priceUsd,
                                    ),
                                    onDelete: () => _confirmDelete(
                                      context,
                                      rowGifts[i].id,
                                      rowGifts[i].name,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String id,
    String name,
    String thumbnailUrl,
    String? animationUrl,
    double priceUsd,
  ) {
    final nameCtrl = TextEditingController(text: name);
    final thumbCtrl = TextEditingController(text: thumbnailUrl);
    final animCtrl = TextEditingController(text: animationUrl ?? '');
    final priceCtrl = TextEditingController(text: priceUsd.toString());
    final formKey = GlobalKey<FormState>();
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('editGift')),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Gift Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: thumbCtrl,
                  decoration: InputDecoration(
                    labelText: 'Thumbnail URL',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: animCtrl,
                  decoration: InputDecoration(
                    labelText: 'Animation URL (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (USD)',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v?.isNotEmpty == true &&
                        double.tryParse(v!.trim()) == null) {
                      return l10n.t('requiredField');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.t('cancel'))),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final price = priceCtrl.text.trim().isEmpty
                  ? null
                  : double.tryParse(priceCtrl.text.trim());
              context.read<GiftsBloc>().add(UpdateGiftEvent(
                    id,
                    UpdateGiftData(
                      name: nameCtrl.text.trim().isEmpty
                          ? null
                          : nameCtrl.text.trim(),
                      thumbnailUrl: thumbCtrl.text.trim().isEmpty
                          ? null
                          : thumbCtrl.text.trim(),
                      animationUrl: animCtrl.text.trim().isEmpty
                          ? null
                          : animCtrl.text.trim(),
                      priceUsd: price,
                    ),
                  ));
            },
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('deleteGiftTitle')),
        content: Text(context.tr('deleteGiftMessage', {'name': name})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.t('cancel'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GiftsBloc>().add(DeleteGiftEvent(id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _SliverSkeletons extends StatelessWidget {
  const _SliverSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        const gap = 12.0;
        const rows = 2;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                return Padding(
                  padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          const Expanded(child: GiftCardSkeleton()),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rows,
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _SliverEmptyState extends StatelessWidget {
  const _SliverEmptyState({
    required this.icon,
    required this.messageKey,
  });

  final IconData icon;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t(messageKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverError extends StatelessWidget {
  const _SliverError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('failedToLoadGifts'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () =>
                    context.read<GiftsBloc>().add(LoadAdminGiftsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.t('retry')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
