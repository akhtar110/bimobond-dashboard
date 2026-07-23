import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_button.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_header.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../../domain/entities/sound_entities.dart';
import '../bloc/sounds_bloc.dart';
import '../utils/sound_display_filters.dart';

/// Search + Filter button row (Gifts-style).
class SoundFiltersPanel extends StatelessWidget {
  const SoundFiltersPanel({
    super.key,
    required this.query,
    this.onStatusChanged,
  });

  final SoundsQuery query;
  final VoidCallback? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeCount = soundsAppliedFilterCount(query);
    const height = 48.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _SoundSearchField(
              hint: l10n.t('soundSearchHint'),
              initialValue: query.search ?? '',
              height: height,
              onChanged: (q) =>
                  context.read<SoundsBloc>().add(SearchSoundsEvent(q)),
            ),
          ),
          const SizedBox(width: 12),
          Builder(
            builder: (buttonContext) {
              return GiftsFilterButton(
                activeCount: activeCount,
                height: height,
                onPressed: () {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                  final size = box?.size ?? Size.zero;
                  showSoundFilterPopup(
                    context: buttonContext,
                    query: query,
                    anchorRect: Rect.fromLTWH(
                      origin.dx,
                      origin.dy,
                      size.width,
                      size.height,
                    ),
                    onStatusChanged: onStatusChanged,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SoundSearchField extends StatefulWidget {
  const _SoundSearchField({
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.height = 48,
  });

  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double height;

  @override
  State<_SoundSearchField> createState() => _SoundSearchFieldState();
}

class _SoundSearchFieldState extends State<_SoundSearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _SoundSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _ctrl.text &&
        widget.initialValue != oldWidget.initialValue) {
      _ctrl.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

Future<void> showSoundFilterPopup({
  required BuildContext context,
  required SoundsQuery query,
  required Rect anchorRect,
  VoidCallback? onStatusChanged,
}) {
  final soundsBloc = context.read<SoundsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<SoundsBloc>.value(
        value: soundsBloc,
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          _SoundFilterPopup(
            query: query,
            soundsBloc: soundsBloc,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            onStatusChanged: onStatusChanged,
          ),
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            _SoundFilterPopup(
              query: query,
              soundsBloc: soundsBloc,
              width: 380,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
              onStatusChanged: onStatusChanged,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 380.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.68;
  if (top + 320 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 320.0);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: wrap(
                _SoundFilterPopup(
                  query: query,
                  soundsBloc: soundsBloc,
                  width: panelWidth,
                  maxHeight: maxPanelHeight,
                  onStatusChanged: onStatusChanged,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SoundFilterPopup extends StatefulWidget {
  const _SoundFilterPopup({
    required this.query,
    required this.soundsBloc,
    this.width,
    this.maxHeight = 480,
    this.borderRadius,
    this.onStatusChanged,
  });

  final SoundsQuery query;
  final SoundsBloc soundsBloc;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final VoidCallback? onStatusChanged;

  @override
  State<_SoundFilterPopup> createState() => _SoundFilterPopupState();
}

class _SoundFilterPopupState extends State<_SoundFilterPopup> {
  late bool? _isActive;
  late SoundSortMode _sort;

  @override
  void initState() {
    super.initState();
    _isActive = widget.query.isActive;
    _sort = widget.query.sort;
  }

  void _reset() {
    setState(() {
      _isActive = null;
      _sort = SoundSortMode.trending;
    });
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _apply() {
    widget.onStatusChanged?.call();
    widget.soundsBloc.add(FilterSoundsActiveEvent(_isActive));
    widget.soundsBloc.add(SortSoundsEvent(_sort));
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    final activeItems = <GiftsActiveFilterItem>[
      if (_isActive != null)
        GiftsActiveFilterItem(
          id: 'status',
          label: _isActive!
              ? l10n.t('soundStatusActive')
              : l10n.t('soundStatusHidden'),
          onRemove: () => setState(() => _isActive = null),
        ),
      if (_sort != SoundSortMode.trending)
        GiftsActiveFilterItem(
          id: 'sort',
          label: switch (_sort) {
            SoundSortMode.trending => l10n.t('soundSortTrending'),
            SoundSortMode.recent => l10n.t('soundSortRecent'),
            SoundSortMode.alphabetical => l10n.t('soundSortName'),
          },
          onRemove: () => setState(() => _sort = SoundSortMode.trending),
        ),
    ];

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.width ?? 380,
        height: widget.maxHeight,
        child: Column(
          children: [
            GiftsFilterHeader(onResetAll: _reset, onClose: _close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  GiftsFilterSection(
                    title: l10n.tOr('status', 'Status').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: l10n.t('all'),
                          selected: _isActive == null,
                          onTap: () => setState(() => _isActive = null),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.t('soundStatusActive'),
                          selected: _isActive == true,
                          onTap: () => setState(() => _isActive = true),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.t('soundStatusHidden'),
                          selected: _isActive == false,
                          onTap: () => setState(() => _isActive = false),
                        ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: l10n.tOr('sortBy', 'Sort').toUpperCase(),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final sort in SoundSortMode.values)
                          GiftsFilterChoiceChip(
                            label: switch (sort) {
                              SoundSortMode.trending =>
                                l10n.t('soundSortTrending'),
                              SoundSortMode.recent => l10n.t('soundSortRecent'),
                              SoundSortMode.alphabetical =>
                                l10n.t('soundSortName'),
                            },
                            selected: _sort == sort,
                            onTap: () => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                  GiftsActiveFilters(items: activeItems),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: _close,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
