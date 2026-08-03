import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    this.draft,
    this.message,
    this.isError = false,
  });

  final ProfileEntity profile;
  final ProfileEntity? draft;
  final String? message;
  final bool isError;

  ProfileEntity get effectiveProfile => draft ?? profile;

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    ProfileEntity? draft,
    String? message,
    bool clearMessage = false,
    bool clearDraft = false,
    bool? isError,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      draft: clearDraft ? null : (draft ?? this.draft),
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [profile, draft, message, isError];
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating({required this.profile, this.draft});

  final ProfileEntity profile;
  final ProfileEntity? draft;

  ProfileEntity get effectiveProfile => draft ?? profile;

  @override
  List<Object?> get props => [profile, draft];
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated({
    required this.profile,
    required this.message,
  });

  final ProfileEntity profile;
  final String message;

  @override
  List<Object?> get props => [profile, message];
}

class ProfileUploadingAvatar extends ProfileState {
  const ProfileUploadingAvatar({required this.profile, this.draft});

  final ProfileEntity profile;
  final ProfileEntity? draft;

  ProfileEntity get effectiveProfile => draft ?? profile;

  @override
  List<Object?> get props => [profile, draft];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message, {this.profile});

  final String message;
  final ProfileEntity? profile;

  @override
  List<Object?> get props => [message, profile];
}
