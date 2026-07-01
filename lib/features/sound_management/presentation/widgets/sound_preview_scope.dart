import 'package:flutter/material.dart';

import '../services/sound_preview_service.dart';

class SoundPreviewScope extends InheritedWidget {
  const SoundPreviewScope({
    super.key,
    required this.preview,
    required super.child,
  });

  final SoundPreviewService preview;

  static SoundPreviewService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SoundPreviewScope>();
    assert(scope != null, 'SoundPreviewScope not found');
    return scope!.preview;
  }

  @override
  bool updateShouldNotify(SoundPreviewScope oldWidget) =>
      preview != oldWidget.preview;
}

class SoundPreviewHost extends StatefulWidget {
  const SoundPreviewHost({super.key, required this.child});

  final Widget child;

  @override
  State<SoundPreviewHost> createState() => _SoundPreviewHostState();
}

class _SoundPreviewHostState extends State<SoundPreviewHost> {
  late final SoundPreviewService _preview = SoundPreviewService();

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SoundPreviewScope(
      preview: _preview,
      child: widget.child,
    );
  }
}

extension SoundPreviewContext on BuildContext {
  SoundPreviewService get soundPreview => SoundPreviewScope.of(this);
}
