import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/save_session_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/update_profile_data.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required UploadAvatarUseCase uploadAvatar,
    required AuthBloc authBloc,
    required SaveSessionUseCase saveSession,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _uploadAvatar = uploadAvatar,
        _authBloc = authBloc,
        _saveSession = saveSession,
        super(const ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<UpdateProfile>(_onUpdate);
    on<UploadAvatar>(_onUploadAvatar);
    on<ChangeProfileField>(_onChangeField);
    on<ClearProfileFeedback>(_onClearFeedback);
  }

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final UploadAvatarUseCase _uploadAvatar;
  final AuthBloc _authBloc;
  final SaveSessionUseCase _saveSession;

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.svg',
  };

  /// Default max image size when settings are unavailable (5 MB).
  static const int defaultMaxAvatarBytes = 5 * 1024 * 1024;

  Future<void> _onLoad(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      emit(const ProfileError('Not authenticated'));
      return;
    }

    emit(const ProfileLoading());
    try {
      final profile = await _getProfile(userId);
      emit(ProfileLoaded(profile: profile, draft: profile));
    } catch (e) {
      emit(ProfileError(_cleanError(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    final profile = _profileFrom(current);
    final draft = _draftFrom(current);

    final username = event.data.username?.trim();
    if (username != null &&
        username.isNotEmpty &&
        !UpdateProfileData.usernamePattern.hasMatch(username)) {
      emit(
        ProfileLoaded(
          profile: profile ??
              ProfileEntity(id: '', username: username),
          draft: draft,
          message:
              'Username must be 3–20 characters (letters, numbers, underscore).',
          isError: true,
        ),
      );
      return;
    }

    if (profile != null) {
      emit(ProfileUpdating(profile: profile, draft: draft));
    }

    try {
      final targetUserId = profile?.id ?? _currentUserId;
      final updated = await _updateProfile(event.data, userId: targetUserId);

      // Merge count metrics from previous profile if the patch response omitted them
      final merged = (profile != null)
          ? updated.copyWith(
              followerCount: updated.followerCount > 0
                  ? updated.followerCount
                  : profile.followerCount,
              followingCount: updated.followingCount > 0
                  ? updated.followingCount
                  : profile.followingCount,
              postCount: updated.postCount > 0
                  ? updated.postCount
                  : profile.postCount,
              totalLikes: updated.totalLikes > 0
                  ? updated.totalLikes
                  : profile.totalLikes,
              balanceCoins: updated.balanceCoins > 0
                  ? updated.balanceCoins
                  : profile.balanceCoins,
              sentGiftsCount: updated.sentGiftsCount > 0
                  ? updated.sentGiftsCount
                  : profile.sentGiftsCount,
              receivedGiftsCount: updated.receivedGiftsCount > 0
                  ? updated.receivedGiftsCount
                  : profile.receivedGiftsCount,
              wonAuctionsCount: updated.wonAuctionsCount > 0
                  ? updated.wonAuctionsCount
                  : profile.wonAuctionsCount,
              reportsRecvCount: updated.reportsRecvCount > 0
                  ? updated.reportsRecvCount
                  : profile.reportsRecvCount,
            )
          : updated;

      await _syncAuthSession(merged);
      emit(ProfileUpdated(
        profile: merged,
        message: 'profile_updated_successfully',
      ));
      emit(ProfileLoaded(profile: merged, draft: merged));
    } catch (e) {
      emit(
        ProfileLoaded(
          profile: profile ??
              ProfileEntity(id: '', username: username ?? ''),
          draft: draft,
          message: _cleanError(e),
          isError: true,
        ),
      );
    }
  }

  Future<void> _onUploadAvatar(
    UploadAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    final profile = _profileFrom(current);
    final draft = _draftFrom(current);

    if (!_isImageFilename(event.filename)) {
      emit(
        ProfileLoaded(
          profile: profile ?? ProfileEntity(id: '', username: ''),
          draft: draft,
          message: 'Only image files are allowed.',
          isError: true,
        ),
      );
      return;
    }

    if (event.bytes.length > defaultMaxAvatarBytes) {
      emit(
        ProfileLoaded(
          profile: profile ?? ProfileEntity(id: '', username: ''),
          draft: draft,
          message: 'Image exceeds the maximum upload size (5 MB).',
          isError: true,
        ),
      );
      return;
    }

    if (profile != null) {
      emit(ProfileUploadingAvatar(profile: profile, draft: draft));
    }

    try {
      final absoluteUrl =
          await _uploadAvatar(event.bytes, event.filename);
      final updated = await _updateProfile(
        UpdateProfileData(avatarUrl: absoluteUrl),
      );
      await _syncAuthSession(updated);
      emit(ProfileUpdated(
        profile: updated,
        message: 'profile_updated_successfully',
      ));
      emit(ProfileLoaded(profile: updated, draft: updated));
    } catch (e) {
      emit(
        ProfileLoaded(
          profile: profile ?? ProfileEntity(id: '', username: ''),
          draft: draft,
          message: _cleanError(e),
          isError: true,
        ),
      );
    }
  }

  void _onChangeField(
    ChangeProfileField event,
    Emitter<ProfileState> emit,
  ) {
    final current = state;
    final profile = _profileFrom(current);
    final base = _draftFrom(current) ?? profile;
    if (profile == null || base == null) return;

    final next = base.copyWith(
      username: event.username,
      fullName: event.fullName,
      bio: event.bio,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
      phoneNumber: event.phoneNumber,
      isPrivate: event.isPrivate,
      allowComments: event.allowComments,
      allowDirectMsgs: event.allowDirectMsgs,
      messagePermission: event.messagePermission,
      language: event.language,
      theme: event.theme,
      instagramUrl: event.instagramUrl,
      youtubeUrl: event.youtubeUrl,
      country: event.country,
      region: event.region,
      city: event.city,
      clearDateOfBirth: event.clearDateOfBirth,
    );

    emit(ProfileLoaded(
      profile: profile,
      draft: next,
    ));
  }

  void _onClearFeedback(
    ClearProfileFeedback event,
    Emitter<ProfileState> emit,
  ) {
    final current = state;
    if (current is ProfileLoaded && current.message != null) {
      emit(current.copyWith(clearMessage: true, isError: false));
    }
  }

  String? get _currentUserId {
    final auth = _authBloc.state;
    if (auth is Authenticated) return auth.user.id;
    return null;
  }

  ProfileEntity? _profileFrom(ProfileState state) {
    return switch (state) {
      ProfileLoaded(:final profile) => profile,
      ProfileUpdating(:final profile) => profile,
      ProfileUploadingAvatar(:final profile) => profile,
      ProfileUpdated(:final profile) => profile,
      ProfileError(:final profile) => profile,
      _ => null,
    };
  }

  ProfileEntity? _draftFrom(ProfileState state) {
    return switch (state) {
      ProfileLoaded(:final draft) => draft,
      ProfileUpdating(:final draft) => draft,
      ProfileUploadingAvatar(:final draft) => draft,
      _ => null,
    };
  }

  Future<void> _syncAuthSession(ProfileEntity profile) async {
    final auth = _authBloc.state;
    if (auth is! Authenticated) return;

    final updatedUser = DashboardUserEntity(
      id: auth.user.id,
      email: auth.user.email,
      username: profile.username,
      fullName: profile.fullName,
      isVerified: profile.isVerified,
      isNewUser: auth.user.isNewUser,
      isProfileIncomplete: auth.user.isProfileIncomplete,
      roles: auth.user.roles,
    );

    await _saveSession(updatedUser);
    _authBloc.add(AuthUserChanged(updatedUser));
  }

  bool _isImageFilename(String filename) {
    final lower = filename.toLowerCase();
    return _imageExtensions.any(lower.endsWith);
  }

  String _cleanError(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}
