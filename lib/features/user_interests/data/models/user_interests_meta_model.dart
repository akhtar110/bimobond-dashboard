import '../../domain/entities/user_interest_entities.dart';

class UserInterestsMetaModel extends UserInterestsMetaEntity {
  const UserInterestsMetaModel({
    super.totalInterests,
    super.totalNotInterests,
    super.minRequired,
    super.maxAllowed,
    super.maxNotInterestsAllowed,
    super.needsInterests,
  });

  factory UserInterestsMetaModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserInterestsMetaModel();
    return UserInterestsMetaModel(
      totalInterests: _int(json['totalInterests'] ?? json['total']),
      totalNotInterests: _int(json['totalNotInterests']),
      minRequired: _int(json['minRequired'], fallback: 3),
      maxAllowed: _int(json['maxAllowed'], fallback: 20),
      maxNotInterestsAllowed:
          _int(json['maxNotInterestsAllowed'], fallback: 20),
      needsInterests: json['needsInterests'] == true,
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
