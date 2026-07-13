import 'package:equatable/equatable.dart';

abstract class FilterEditorEvent extends Equatable {
  const FilterEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadFilterEditorEvent extends FilterEditorEvent {
  const LoadFilterEditorEvent({this.filterId});

  final String? filterId;

  @override
  List<Object?> get props => [filterId];
}

class LoadFilterSchemaEvent extends FilterEditorEvent {
  const LoadFilterSchemaEvent();
}

class LoadFilterDetailEvent extends FilterEditorEvent {
  const LoadFilterDetailEvent(this.filterId);

  final String filterId;

  @override
  List<Object?> get props => [filterId];
}

class FilterBasicFieldChanged extends FilterEditorEvent {
  const FilterBasicFieldChanged({
    this.slug,
    this.engineKey,
    this.engineType,
    this.labelKey,
    this.customLabel,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isOriginal,
    this.isBeautyDefault,
    this.isActive,
    this.sortOrder,
    this.clearLabelKey = false,
    this.clearCustomLabel = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
  });

  final String? slug;
  final String? engineKey;
  final String? engineType;
  final String? labelKey;
  final String? customLabel;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool? isOriginal;
  final bool? isBeautyDefault;
  final bool? isActive;
  final int? sortOrder;
  final bool clearLabelKey;
  final bool clearCustomLabel;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;

  @override
  List<Object?> get props => [
        slug,
        engineKey,
        engineType,
        labelKey,
        customLabel,
        thumbnailUrl,
        previewColorHex,
        isOriginal,
        isBeautyDefault,
        isActive,
        sortOrder,
        clearLabelKey,
        clearCustomLabel,
        clearThumbnailUrl,
        clearPreviewColorHex,
      ];
}

class FilterSliderChanged extends FilterEditorEvent {
  const FilterSliderChanged({required this.key, required this.value});

  final String key;
  final int value;

  @override
  List<Object?> get props => [key, value];
}

class FilterPreviewColorChanged extends FilterEditorEvent {
  const FilterPreviewColorChanged(this.hex);

  final String? hex;

  @override
  List<Object?> get props => [hex];
}

class FilterSettingsSearchChanged extends FilterEditorEvent {
  const FilterSettingsSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterGroupExpansionToggled extends FilterEditorEvent {
  const FilterGroupExpansionToggled(this.groupKey);

  final String groupKey;

  @override
  List<Object?> get props => [groupKey];
}

class FilterToggleAllGroupsEvent extends FilterEditorEvent {
  const FilterToggleAllGroupsEvent({required this.expand});

  final bool expand;

  @override
  List<Object?> get props => [expand];
}

class ResetFilterSettingsEvent extends FilterEditorEvent {
  const ResetFilterSettingsEvent();
}

class ResetFilterEditorEvent extends FilterEditorEvent {
  const ResetFilterEditorEvent();
}

class SubmitFilterEditorEvent extends FilterEditorEvent {
  const SubmitFilterEditorEvent();
}

class UploadFilterThumbnailEvent extends FilterEditorEvent {
  const UploadFilterThumbnailEvent({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}

class ClearFilterEditorSaveFlagEvent extends FilterEditorEvent {
  const ClearFilterEditorSaveFlagEvent();
}

class ClearFilterEditorSubmitErrorEvent extends FilterEditorEvent {
  const ClearFilterEditorSubmitErrorEvent();
}
