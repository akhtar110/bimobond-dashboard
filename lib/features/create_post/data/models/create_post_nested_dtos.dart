import '../../domain/entities/create_post_location_entity.dart';
import '../../domain/entities/create_post_new_sound_entity.dart';

class CreateLocationDto {
  const CreateLocationDto({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.countryCode,
    this.placeId,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? countryCode;
  final String? placeId;

  factory CreateLocationDto.fromEntity(CreatePostLocationEntity entity) {
    return CreateLocationDto(
      name: entity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      city: entity.city,
      countryCode: entity.countryCode,
      placeId: entity.placeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (address != null && address!.trim().isNotEmpty)
          'address': address!.trim(),
        if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
        if (countryCode != null && countryCode!.trim().isNotEmpty)
          'countryCode': countryCode!.trim(),
        if (placeId != null && placeId!.trim().isNotEmpty)
          'placeId': placeId!.trim(),
      };
}

class CreateNewSoundDto {
  const CreateNewSoundDto({
    required this.audioUrl,
    required this.duration,
    this.name,
    this.coverUrl,
    this.originalSoundId,
  });

  final String audioUrl;
  final int duration;
  final String? name;
  final String? coverUrl;
  final String? originalSoundId;

  factory CreateNewSoundDto.fromEntity(CreatePostNewSoundEntity entity) {
    return CreateNewSoundDto(
      audioUrl: entity.audioUrl,
      duration: entity.duration,
      name: entity.name,
      coverUrl: entity.coverUrl,
      originalSoundId: entity.originalSoundId,
    );
  }

  Map<String, dynamic> toJson() => {
        'audioUrl': audioUrl.trim(),
        'duration': duration,
        if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
        if (coverUrl != null && coverUrl!.trim().isNotEmpty)
          'coverUrl': coverUrl!.trim(),
        if (originalSoundId != null && originalSoundId!.trim().isNotEmpty)
          'originalSoundId': originalSoundId!.trim(),
      };
}
