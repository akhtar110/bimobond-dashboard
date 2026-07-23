import 'package:equatable/equatable.dart';

/// Non-destructive adjustments applied to image media before upload.
class CreatePostMediaFilterEntity extends Equatable {
  const CreatePostMediaFilterEntity({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.exposure = 0,
    this.sharpen = 0,
    this.blur = 0,
    this.catalogFilterId,
    this.catalogFilterLabel,
    this.catalogColorMatrix,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double exposure;
  final double sharpen;
  final double blur;
  final String? catalogFilterId;
  final String? catalogFilterLabel;
  final List<double>? catalogColorMatrix;

  static const neutral = CreatePostMediaFilterEntity();

  bool get usesCatalogFilter =>
      catalogFilterId != null && catalogFilterId!.trim().isNotEmpty;

  bool get hasCustomAdjustments =>
      brightness != 0 ||
      contrast != 0 ||
      saturation != 0 ||
      warmth != 0 ||
      exposure != 0 ||
      sharpen != 0 ||
      blur != 0;

  bool get isNeutral => !usesCatalogFilter && !hasCustomAdjustments;

  CreatePostMediaFilterEntity copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? exposure,
    double? sharpen,
    double? blur,
    String? catalogFilterId,
    String? catalogFilterLabel,
    List<double>? catalogColorMatrix,
    bool clearCatalogFilter = false,
    bool clearCustomAdjustments = false,
  }) {
    return CreatePostMediaFilterEntity(
      brightness: clearCustomAdjustments ? 0 : (brightness ?? this.brightness),
      contrast: clearCustomAdjustments ? 0 : (contrast ?? this.contrast),
      saturation: clearCustomAdjustments ? 0 : (saturation ?? this.saturation),
      warmth: clearCustomAdjustments ? 0 : (warmth ?? this.warmth),
      exposure: clearCustomAdjustments ? 0 : (exposure ?? this.exposure),
      sharpen: clearCustomAdjustments ? 0 : (sharpen ?? this.sharpen),
      blur: clearCustomAdjustments ? 0 : (blur ?? this.blur),
      catalogFilterId:
          clearCatalogFilter ? null : (catalogFilterId ?? this.catalogFilterId),
      catalogFilterLabel: clearCatalogFilter
          ? null
          : (catalogFilterLabel ?? this.catalogFilterLabel),
      catalogColorMatrix: clearCatalogFilter
          ? null
          : (catalogColorMatrix ?? this.catalogColorMatrix),
    );
  }

  CreatePostMediaFilterEntity withCatalogFilter({
    required String id,
    required String label,
    List<double>? colorMatrix,
  }) {
    return copyWith(
      clearCustomAdjustments: true,
      catalogFilterId: id,
      catalogFilterLabel: label,
      catalogColorMatrix:
          colorMatrix != null && colorMatrix.length >= 20 ? colorMatrix : null,
    );
  }

  CreatePostMediaFilterEntity withCustomAdjustments({
    required CreatePostMediaFilterEntity adjustments,
  }) {
    return CreatePostMediaFilterEntity(
      brightness: adjustments.brightness,
      contrast: adjustments.contrast,
      saturation: adjustments.saturation,
      warmth: adjustments.warmth,
      exposure: adjustments.exposure,
      sharpen: adjustments.sharpen,
      blur: adjustments.blur,
    );
  }

  @override
  List<Object?> get props => [
        brightness,
        contrast,
        saturation,
        warmth,
        exposure,
        sharpen,
        blur,
        catalogFilterId,
        catalogFilterLabel,
        catalogColorMatrix,
      ];
}
