import 'package:bimo_bond_dashboard/features/filters_effects/data/datasources/filters_effects_remote_datasource.dart';
import 'package:bimo_bond_dashboard/features/filters_effects/domain/entities/filters_effects_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Camera Studio AR contract parsing', () {
    test('parses filter with adjustments preferred over filterSettings', () {
      final filter = CameraFilterModel.fromJson({
        'id': 'uuid-1',
        'slug': 'whitening',
        'renderType': 'matrix',
        'label': 'Pure',
        'customLabel': 'Pure',
        'labelKey': 'cameraFilter_whitening',
        'emoji': '🤍',
        'previewColorHex': '#F0E0D0',
        'adjustments': {'brightness': 8},
        'filterSettings': {'brightness': 99},
        'colorMatrix': List<double>.filled(20, 1),
        'isOriginal': false,
        'isBeautyDefault': false,
        'isActive': true,
        'sortOrder': 0,
      });

      expect(filter.renderType, CameraFilterRenderTypeApi.matrix);
      expect(filter.displayLabel, 'Pure');
      expect(filter.effectiveAdjustments.values['brightness'], 8);
      expect(filter.colorMatrix, hasLength(20));
    });

    test('falls back to filterSettings when adjustments empty', () {
      final filter = CameraFilterModel.fromJson({
        'id': 'uuid-2',
        'slug': 'film',
        'renderType': 'lut',
        'label': 'Film',
        'filterSettings': {'warmth': 10},
        'lutAsset': 'film.png',
        'isActive': true,
        'sortOrder': 1,
      });

      expect(filter.renderType, CameraFilterRenderTypeApi.lut);
      expect(filter.effectiveAdjustments.values['warmth'], 10);
      expect(filter.lutAsset, 'film.png');
    });

    test('parses catalog with colorFilterCategories alias', () {
      final catalog = CameraStudioCatalogModel.fromJson({
        'version': '2026-07-20T01',
        'colorFilterCategories': [
          {
            'id': 'cat-1',
            'slug': 'portrait',
            'label': 'Portrait',
            'sortOrder': 0,
            'isActive': true,
            'filters': [],
          },
        ],
        'effectCategories': [],
      });

      expect(catalog.version, '2026-07-20T01');
      expect(catalog.filterCategories, hasLength(1));
      expect(catalog.filterCategories.first.displayLabel, 'Portrait');
    });

    test('parses seed success body', () {
      final seed = CatalogSeedResultModel.fromJson({
        'success': true,
        'message': 'AR Camera catalog reseeded',
      });
      expect(seed.success, isTrue);
      expect(seed.message, 'AR Camera catalog reseeded');
    });

    test('writes uppercase render types on create requests', () {
      final filterJson = const CreateFilterRequest(
        slug: 'whitening',
        renderType: 'matrix',
        label: 'Pure',
        colorMatrix: [
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ],
      ).toJson();
      expect(filterJson['renderType'], 'MATRIX');

      final effectJson = const CreateEffectRequest(
        slug: 'glasses',
        renderType: 'sticker',
        label: 'Glasses',
        assetAsset: 'glasses.png',
        anchor: {'pinX': 'nose_bridge'},
      ).toJson();
      expect(effectJson['renderType'], 'STICKER');
      expect(effectJson['anchor'], isA<Map>());
    });

    test('category create requires label', () {
      final json = const CreateCategoryRequest(
        slug: 'portrait',
        label: 'Portrait',
        labelKey: 'cameraCategoryPortrait',
      ).toJson();
      expect(json['label'], 'Portrait');
      expect(json['slug'], 'portrait');
    });
  });
}
