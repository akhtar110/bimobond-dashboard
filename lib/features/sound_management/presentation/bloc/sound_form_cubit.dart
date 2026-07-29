import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/sound_entities.dart';
import '../../domain/repositories/sound_management_repository.dart';
import '../utils/sound_audio_duration_parser.dart';
import '../utils/sound_audio_duration_web.dart';
import '../utils/sound_file_picker_web.dart';

class SoundFormState extends Equatable {
  const SoundFormState({
    required this.isEditing,
    this.audioFilename,
    this.audioBytes,
    this.audioUrl = '',
    this.coverFilename,
    this.coverBytes,
    this.coverPreviewBytes,
    this.coverUrl,
    this.uploadingCover = false,
    this.coverError,
    this.fileError,
    this.detectedDuration,
    this.detectingDuration = false,
  });

  final bool isEditing;
  final String? audioFilename;
  final Uint8List? audioBytes;
  final String audioUrl;
  final String? coverFilename;
  final List<int>? coverBytes;
  final Uint8List? coverPreviewBytes;
  final String? coverUrl;
  final bool uploadingCover;
  final String? coverError;
  final String? fileError;
  final int? detectedDuration;
  final bool detectingDuration;

  bool get hasAudio {
    if (audioBytes != null && audioBytes!.isNotEmpty) return true;
    return audioUrl.trim().isNotEmpty;
  }

  bool get hasCover =>
      (coverPreviewBytes != null && coverPreviewBytes!.isNotEmpty) ||
      (coverUrl != null && coverUrl!.trim().isNotEmpty) ||
      (coverBytes != null && coverBytes!.isNotEmpty);

  bool get isBusy => detectingDuration || uploadingCover;

  String? get resolvedAudioUrl {
    final trimmed = audioUrl.trim();
    if (trimmed.isEmpty) return null;
    return resolveMediaUrl(trimmed) ?? trimmed;
  }

  String? get resolvedCoverUrl {
    final trimmed = coverUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return resolveMediaUrl(trimmed) ?? trimmed;
  }

  SoundFormState copyWith({
    String? audioFilename,
    Uint8List? audioBytes,
    String? audioUrl,
    String? coverFilename,
    List<int>? coverBytes,
    Uint8List? coverPreviewBytes,
    String? coverUrl,
    bool? uploadingCover,
    String? coverError,
    String? fileError,
    int? detectedDuration,
    bool? detectingDuration,
    bool clearAudio = false,
    bool clearCover = false,
    bool clearCoverError = false,
    bool clearFileError = false,
    bool clearDetectedDuration = false,
  }) {
    return SoundFormState(
      isEditing: isEditing,
      audioFilename: clearAudio ? null : (audioFilename ?? this.audioFilename),
      audioBytes: clearAudio ? null : (audioBytes ?? this.audioBytes),
      audioUrl: audioUrl ?? this.audioUrl,
      coverFilename: clearCover ? null : (coverFilename ?? this.coverFilename),
      coverBytes: clearCover ? null : (coverBytes ?? this.coverBytes),
      coverPreviewBytes:
          clearCover ? null : (coverPreviewBytes ?? this.coverPreviewBytes),
      coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
      uploadingCover: uploadingCover ?? this.uploadingCover,
      coverError: clearCoverError
          ? null
          : (coverError ?? (clearCover ? null : this.coverError)),
      fileError: clearFileError
          ? null
          : (fileError ?? (clearAudio ? null : this.fileError)),
      detectedDuration: clearDetectedDuration || clearAudio
          ? null
          : (detectedDuration ?? this.detectedDuration),
      detectingDuration: detectingDuration ?? this.detectingDuration,
    );
  }

  @override
  List<Object?> get props => [
        isEditing,
        audioFilename,
        audioBytes?.length,
        identityHashCode(audioBytes),
        audioUrl,
        coverFilename,
        coverBytes?.length,
        identityHashCode(coverBytes),
        coverPreviewBytes?.length,
        identityHashCode(coverPreviewBytes),
        coverUrl,
        uploadingCover,
        coverError,
        fileError,
        detectedDuration,
        detectingDuration,
      ];
}

class SoundFormCubit extends Cubit<SoundFormState> {
  SoundFormCubit({
    required SoundManagementRepository repository,
    SoundEntity? sound,
  })  : _repository = repository,
        super(
          SoundFormState(
            isEditing: sound != null,
            audioUrl: resolveMediaUrl(sound?.audioUrl) ?? sound?.audioUrl ?? '',
            coverUrl: resolveMediaUrl(sound?.coverUrl) ?? sound?.coverUrl,
            detectedDuration: sound?.duration,
          ),
        );

  final SoundManagementRepository _repository;

  void setFileError(String? message) {
    emit(state.copyWith(fileError: message, clearFileError: message == null));
  }

  Future<void> pickAudio({
    required String Function() maxSizeMessage,
    required String Function() invalidFormatMessage,
  }) async {
    final picked = await pickAudioFile();
    if (picked == null || isClosed) return;

    if (picked.bytes.length > kMaxAudioUploadBytes) {
      emit(state.copyWith(fileError: maxSizeMessage()));
      return;
    }
    if (!isAllowedAudioFilename(picked.name)) {
      emit(state.copyWith(fileError: invalidFormatMessage()));
      return;
    }

    emit(
      state.copyWith(
        detectingDuration: true,
        clearFileError: true,
        audioBytes: picked.bytes,
        audioFilename: picked.name,
        clearDetectedDuration: true,
      ),
    );

    final duration = parseAudioDurationFromBytes(picked.bytes, picked.name) ??
        await probeAudioDurationFromBytes(picked.bytes, picked.name);
    if (isClosed) return;

    emit(
      state.copyWith(
        detectingDuration: false,
        detectedDuration: duration,
      ),
    );
  }

  void clearAudio() {
    emit(
      state.copyWith(
        clearAudio: true,
        detectingDuration: false,
      ),
    );
  }

  Future<void> pickCover() async {
    final picked = await pickCoverImageFile();
    if (picked == null || isClosed) return;

    if (state.isEditing) {
      emit(
        state.copyWith(
          coverPreviewBytes: picked.bytes,
          coverFilename: picked.name,
          uploadingCover: true,
          clearCoverError: true,
        ),
      );
      try {
        final url = await _repository.uploadSoundFile(
          picked.bytes,
          picked.name,
        );
        if (isClosed) return;
        emit(
          state.copyWith(
            coverUrl: url,
            coverBytes: picked.bytes,
            uploadingCover: false,
          ),
        );
      } catch (e) {
        if (isClosed) return;
        emit(
          state.copyWith(
            uploadingCover: false,
            clearCover: true,
            coverError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
      return;
    }

    emit(
      state.copyWith(
        coverBytes: picked.bytes,
        coverFilename: picked.name,
        coverPreviewBytes: picked.bytes,
        clearCoverError: true,
      ),
    );
  }

  void clearCover() {
    emit(
      state.copyWith(
        clearCover: true,
        uploadingCover: false,
      ),
    );
  }
}
