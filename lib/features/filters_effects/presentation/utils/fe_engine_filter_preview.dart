import 'package:flutter/material.dart';

import '../../../../core/utils/camera_engine_filter_look.dart';

export '../../../../core/utils/camera_engine_filter_look.dart'
    show CameraEngineFilterLook;

typedef FeEnginePreviewLook = CameraEngineFilterLook;

FeEnginePreviewLook enginePreviewLookForKey(String? engineKey) =>
    cameraEngineFilterLookForKey(engineKey);

/// Applies the engine filter look to [child] (typically the preview photo).
Widget applyEnginePreviewLook({
  required Widget child,
  required String? engineKey,
}) =>
    applyCameraEngineFilterLook(child: child, engineKey: engineKey);
