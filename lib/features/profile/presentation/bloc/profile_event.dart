import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/update_profile_data.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfile extends ProfileEvent {
  const UpdateProfile(this.data);

  final UpdateProfileData data;

  @override
  List<Object?> get props => [data];
}

class UploadAvatar extends ProfileEvent {
  const UploadAvatar({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}

/// Local draft field updates while editing (does not hit the API).
class ChangeProfileField extends ProfileEvent {
  const ChangeProfileField({
    this.username,
    this.fullName,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.isPrivate,
    this.allowComments,
    this.allowDirectMsgs,
    this.messagePermission,
    this.language,
    this.theme,
    this.instagramUrl,
    this.youtubeUrl,
    this.country,
    this.region,
    this.city,
    this.clearDateOfBirth = false,
  });

  final String? username;
  final String? fullName;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final bool? isPrivate;
  final bool? allowComments;
  final bool? allowDirectMsgs;
  final String? messagePermission;
  final String? language;
  final String? theme;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? country;
  final String? region;
  final String? city;
  final bool clearDateOfBirth;

  @override
  List<Object?> get props => [
        username,
        fullName,
        bio,
        gender,
        dateOfBirth,
        phoneNumber,
        isPrivate,
        allowComments,
        allowDirectMsgs,
        messagePermission,
        language,
        theme,
        instagramUrl,
        youtubeUrl,
        country,
        region,
        city,
        clearDateOfBirth,
      ];
}

class ClearProfileFeedback extends ProfileEvent {
  const ClearProfileFeedback();
}
