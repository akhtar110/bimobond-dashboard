import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import 'posts_location_filter.dart';
import 'posts_location_search_field.dart';

const _kLocationPickerTitle = 'Location';

/// Place search field styled like [PostsDateRangePicker] fields.
class PostsLocationPicker extends StatelessWidget {
  const PostsLocationPicker({
    super.key,
    required this.place,
    required this.onChanged,
  });

  final CreatePostLocationEntity? place;
  final ValueChanged<CreatePostLocationEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PostsLocationSearchField(
      dialogStyle: true,
      selectedPlace: place,
      onPlaceSelected: (selected) => onChanged(selected),
      onSelectionCleared: () => onChanged(null),
      onClear: () => onChanged(null),
    );
  }
}

/// Location section inside the filter popup.
class PostsLocationFilterPanel extends StatelessWidget {
  const PostsLocationFilterPanel({
    super.key,
    required this.place,
    required this.onPlaceChanged,
    required this.onClear,
  });

  final CreatePostLocationEntity? place;
  final ValueChanged<CreatePostLocationEntity> onPlaceChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PostsLocationSearchField(
      compact: true,
      selectedPlace: place,
      onPlaceSelected: onPlaceChanged,
      onClear: onClear,
    );
  }
}

String postsLocationPickerTitle(AppLocalizations l10n) =>
    l10n.tOr('postFilterLocationSearch', _kLocationPickerTitle);

CreatePostLocationEntity? postsLocationFromFilters(PostFilters filters) {
  final city = filters.locationCity?.trim();
  if (city == null || city.isEmpty) return null;

  if (filters.hasLocationAnchor) {
    return CreatePostLocationEntity(
      name: city,
      latitude: filters.locationLatitude!,
      longitude: filters.locationLongitude!,
      city: city,
    );
  }

  return CreatePostLocationEntity(
    name: city,
    city: city,
    latitude: 0,
    longitude: 0,
  );
}

String locationFilterLabelFromPlace(CreatePostLocationEntity place) {
  final name = place.name.trim();
  if (name.contains(',')) return name;
  final city = place.city?.trim();
  final country = place.countryCode?.trim();
  if (city != null &&
      city.isNotEmpty &&
      country != null &&
      country.isNotEmpty) {
    return '$city, $country';
  }
  if (city != null && city.isNotEmpty) return city;
  return name;
}

/// Responsive location search dialog — matches [showPostsDateRangePickerDialog].
Future<void> showPostsLocationPickerDialog({
  required BuildContext context,
  required CreatePostLocationEntity? place,
  required void Function(CreatePostLocationEntity? place) onApply,
}) {
  final width = MediaQuery.sizeOf(context).width;

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _PostsLocationPickerSheet(
              place: place,
              onApply: onApply,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              showDragHandle: true,
            ),
          ),
        );
      },
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      final screenWidth = media.size.width;
      final screenHeight = media.size.height;
      final dialogWidth = (screenWidth * 0.92).clamp(340.0, 480.0);
      final maxDialogHeight = screenHeight * 0.75;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 900 ? 20 : 40,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: _PostsLocationPickerSheet(
            place: place,
            onApply: onApply,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    },
  );
}

/// Opens the location picker bound to [PostsBloc] filters.
Future<void> showPostsLocationFilterDialog({
  required BuildContext context,
  required PostFilters filters,
}) {
  final postsBloc = context.read<PostsBloc>();
  final draftPlace = postsLocationFromFilters(filters);

  return showPostsLocationPickerDialog(
    context: context,
    place: draftPlace,
    onApply: (place) {
      if (place == null) {
        postsBloc.add(
          UpdatePostFiltersEvent(postsFiltersClearLocation(filters)),
        );
        return;
      }

      final label = locationFilterLabelFromPlace(place);
      if (label.isEmpty) {
        postsBloc.add(
          UpdatePostFiltersEvent(postsFiltersClearLocation(filters)),
        );
        return;
      }

      postsBloc.add(
        UpdatePostFiltersEvent(postsFiltersWithPlaceName(filters, label)),
      );
    },
  );
}

class _PostsLocationPickerSheet extends StatefulWidget {
  const _PostsLocationPickerSheet({
    required this.place,
    required this.onApply,
    required this.borderRadius,
    this.showDragHandle = false,
  });

  final CreatePostLocationEntity? place;
  final void Function(CreatePostLocationEntity? place) onApply;
  final BorderRadius borderRadius;
  final bool showDragHandle;

  @override
  State<_PostsLocationPickerSheet> createState() =>
      _PostsLocationPickerSheetState();
}

class _PostsLocationPickerSheetState extends State<_PostsLocationPickerSheet> {
  CreatePostLocationEntity? _draftPlace;

  @override
  void initState() {
    super.initState();
    _draftPlace = widget.place;
  }

  void _apply() {
    widget.onApply(_draftPlace);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _draftPlace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final topPadding = widget.showDragHandle ? 10.0 : 22.0;

    return Material(
      color: scheme.surface,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showDragHandle)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Text(
              postsLocationPickerTitle(l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 20),
            PostsLocationPicker(
              place: _draftPlace,
              onChanged: (place) => setState(() => _draftPlace = place),
            ),
            const SizedBox(height: 20),
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.tOr('apply', 'Apply')),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          child: Text(l10n.tOr('clear', 'Clear')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.tOr('cancel', 'Cancel')),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.tOr('cancel', 'Cancel')),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: Text(l10n.tOr('clear', 'Clear')),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.tOr('apply', 'Apply')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Toolbar control — opens the location picker dialog.
class PostsLocationFilterToolbarButton extends StatelessWidget {
  const PostsLocationFilterToolbarButton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PostsBloc, PostsState, PostFilters>(
      selector: (state) => switch (state) {
        PostsLoaded(:final filters) => filters,
        PostsEmpty(:final filters) => filters,
        _ => context.read<PostsBloc>().activeFilters,
      },
      builder: (context, filters) {
        final isActive = filters.hasLocationProximityFilter;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('postFilterLocationSearch'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => showPostsLocationFilterDialog(
                context: context,
                filters: filters,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: height,
                width: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.place_outlined, size: 18, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }
}
