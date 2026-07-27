import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../utils/ar_overlay_asset_kind.dart';
import '../utils/ar_overlay_lottie_cache.dart';

class ArOverlayMediaPreviewState extends Equatable {
  const ArOverlayMediaPreviewState({
    this.kind,
    this.composition,
    this.videoNetworkUrl,
    this.videoBytes,
    this.videoFileName,
    this.loading = false,
    this.error,
    this.cacheKey = '',
  });

  final ArOverlayAssetKind? kind;
  final LottieComposition? composition;
  final String? videoNetworkUrl;
  final Uint8List? videoBytes;
  final String? videoFileName;
  final bool loading;
  final Object? error;
  final String cacheKey;

  bool get isVideo => kind == ArOverlayAssetKind.video;
  bool get isLottie => kind == ArOverlayAssetKind.lottie;

  @override
  List<Object?> get props => [
        kind,
        composition,
        videoNetworkUrl,
        videoBytes,
        videoFileName,
        loading,
        error,
        cacheKey,
      ];
}

/// Loads overlay animation bytes, sniffs JSON vs MP4, and prepares preview data.
class ArOverlayMediaPreviewCubit extends Cubit<ArOverlayMediaPreviewState> {
  ArOverlayMediaPreviewCubit() : super(const ArOverlayMediaPreviewState());

  int _loadToken = 0;

  Future<void> load({
    String? networkUrl,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final token = ++_loadToken;
    final cacheKey = _cacheKey(networkUrl: networkUrl, bytes: bytes);

    emit(
      ArOverlayMediaPreviewState(
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
          ArOverlayMediaPreviewState(
            loading: false,
            error: 'No overlay media data',
            cacheKey: cacheKey,
          ),
        );
        return;
      }

      final kind = resolveArOverlayAssetKind(
            nameOrUrl: fileName ?? url,
            bytes: data,
          ) ??
          (arOverlayBytesLookLikeMp4(data)
              ? ArOverlayAssetKind.video
              : ArOverlayAssetKind.lottie);

      if (kind == ArOverlayAssetKind.video) {
        if (url != null && url.isNotEmpty) {
          ArOverlayLottieCache.putBytes(url, data);
        }
        emit(
          ArOverlayMediaPreviewState(
            kind: ArOverlayAssetKind.video,
            videoNetworkUrl: (url != null && url.isNotEmpty)
                ? (resolveMediaUrl(url) ?? url)
                : null,
            videoBytes: data,
            videoFileName: fileName ?? 'overlay.mp4',
            loading: false,
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
        ArOverlayMediaPreviewState(
          kind: ArOverlayAssetKind.lottie,
          composition: composition,
          loading: false,
          cacheKey: cacheKey,
        ),
      );
    } catch (e) {
      if (isClosed || token != _loadToken) return;
      emit(
        ArOverlayMediaPreviewState(
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
