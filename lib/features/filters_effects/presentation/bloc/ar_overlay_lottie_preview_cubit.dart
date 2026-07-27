import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../utils/ar_overlay_lottie_cache.dart';

class ArOverlayLottiePreviewState extends Equatable {
  const ArOverlayLottiePreviewState({
    this.composition,
    this.loading = false,
    this.error,
    this.cacheKey = '',
  });

  final LottieComposition? composition;
  final bool loading;
  final Object? error;
  final String cacheKey;

  ArOverlayLottiePreviewState copyWith({
    LottieComposition? composition,
    bool? loading,
    Object? error,
    String? cacheKey,
    bool clearComposition = false,
    bool clearError = false,
  }) {
    return ArOverlayLottiePreviewState(
      composition:
          clearComposition ? null : (composition ?? this.composition),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      cacheKey: cacheKey ?? this.cacheKey,
    );
  }

  @override
  List<Object?> get props => [composition, loading, error, cacheKey];
}

class ArOverlayLottiePreviewCubit extends Cubit<ArOverlayLottiePreviewState> {
  ArOverlayLottiePreviewCubit() : super(const ArOverlayLottiePreviewState());

  int _loadToken = 0;

  Future<void> load({String? networkUrl, Uint8List? bytes}) async {
    final token = ++_loadToken;
    final cacheKey = _cacheKey(networkUrl: networkUrl, bytes: bytes);

    final cached = ArOverlayLottieCache.peekComposition(cacheKey);
    if (cached != null) {
      emit(
        ArOverlayLottiePreviewState(
          composition: cached,
          loading: false,
          cacheKey: cacheKey,
        ),
      );
      return;
    }

    emit(
      ArOverlayLottiePreviewState(
        loading: true,
        cacheKey: cacheKey,
      ),
    );

    try {
      Uint8List? data = bytes;
      final url = networkUrl?.trim();
      if ((data == null || data.isEmpty) && url != null && url.isNotEmpty) {
        data = await ArOverlayLottieCache.getBytes(url);
      }
      if (isClosed || token != _loadToken) return;
      if (data == null || data.isEmpty) {
        emit(
          ArOverlayLottiePreviewState(
            loading: false,
            error: 'No Lottie data',
            cacheKey: cacheKey,
          ),
        );
        return;
      }

      final composition = await LottieComposition.fromBytes(_stripBom(data));
      if (isClosed || token != _loadToken) return;
      ArOverlayLottieCache.putComposition(cacheKey, composition);
      if (url != null && url.isNotEmpty) {
        ArOverlayLottieCache.putBytes(url, data);
      }
      emit(
        ArOverlayLottiePreviewState(
          composition: composition,
          loading: false,
          cacheKey: cacheKey,
        ),
      );
    } catch (e) {
      if (isClosed || token != _loadToken) return;
      emit(
        ArOverlayLottiePreviewState(
          loading: false,
          error: e,
          cacheKey: cacheKey,
        ),
      );
    }
  }

  static String _cacheKey({String? networkUrl, Uint8List? bytes}) {
    final url = networkUrl?.trim() ?? '';
    if (url.isNotEmpty) return resolveMediaUrl(url) ?? url;
    if (bytes != null && bytes.isNotEmpty) {
      return 'bytes:${bytes.length}:${bytes.hashCode}';
    }
    return 'empty';
  }

  static Uint8List _stripBom(Uint8List raw) {
    if (raw.length >= 3 &&
        raw[0] == 0xEF &&
        raw[1] == 0xBB &&
        raw[2] == 0xBF) {
      return raw.sublist(3);
    }
    return raw;
  }
}
