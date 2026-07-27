import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../bloc/ar_overlay_lottie_preview_cubit.dart';

/// Smooth AR-overlay Lottie player driven by [ArOverlayLottiePreviewCubit].
class ArOverlayLottiePlayer extends StatelessWidget {
  const ArOverlayLottiePlayer({
    super.key,
    this.networkUrl,
    this.bytes,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArOverlayLottiePreviewCubit()
        ..load(networkUrl: networkUrl, bytes: bytes),
      child: _ArOverlayLottiePlayerView(
        networkUrl: networkUrl,
        bytes: bytes,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      ),
    );
  }
}

class _ArOverlayLottiePlayerView extends StatefulWidget {
  const _ArOverlayLottiePlayerView({
    this.networkUrl,
    this.bytes,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  State<_ArOverlayLottiePlayerView> createState() =>
      _ArOverlayLottiePlayerViewState();
}

class _ArOverlayLottiePlayerViewState extends State<_ArOverlayLottiePlayerView> {
  @override
  void didUpdateWidget(covariant _ArOverlayLottiePlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.networkUrl != widget.networkUrl) {
      context.read<ArOverlayLottiePreviewCubit>().load(
            networkUrl: widget.networkUrl,
            bytes: widget.bytes,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ArOverlayLottiePreviewCubit, ArOverlayLottiePreviewState>(
      buildWhen: (prev, next) =>
          prev.loading != next.loading ||
          prev.error != next.error ||
          prev.composition != next.composition,
      builder: (context, state) {
        final error = state.error;
        if (error != null) {
          return widget.errorBuilder?.call(context, error) ??
              Center(
                child: Icon(Icons.error_outline, color: scheme.error),
              );
        }
        if (state.loading || state.composition == null) {
          return widget.loadingBuilder?.call(context) ??
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
              );
        }

        return RepaintBoundary(
          child: Lottie(
            composition: state.composition,
            fit: BoxFit.contain,
            repeat: true,
            frameRate: const FrameRate(30),
            renderCache: RenderCache.drawingCommands,
            addRepaintBoundary: false,
          ),
        );
      },
    );
  }
}
