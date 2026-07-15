import '../../domain/entities/user_interest_entities.dart';
import 'user_interest_model.dart';
import 'user_interests_meta_model.dart';

class UserInterestsResponseModel extends UserInterestsResponseEntity {
  const UserInterestsResponseModel({
    super.interests,
    super.notInterests,
    super.meta,
  });

  factory UserInterestsResponseModel.fromJson(Map<String, dynamic> json) {
    final interests = _parseList(json['interests']);
    final notInterests = _parseList(json['notInterests']);
    final metaJson = json['meta'];
    final meta = UserInterestsMetaModel.fromJson(
      metaJson is Map<String, dynamic>
          ? metaJson
          : metaJson is Map
              ? Map<String, dynamic>.from(metaJson)
              : null,
    );

    return UserInterestsResponseModel(
      interests: interests,
      notInterests: notInterests,
      meta: UserInterestsMetaModel(
        totalInterests: meta.totalInterests > 0
            ? meta.totalInterests
            : interests.length,
        totalNotInterests: meta.totalNotInterests > 0
            ? meta.totalNotInterests
            : notInterests.length,
        minRequired: meta.minRequired,
        maxAllowed: meta.maxAllowed,
        maxNotInterestsAllowed: meta.maxNotInterestsAllowed,
        needsInterests: meta.needsInterests,
      ),
    );
  }

  static List<UserInterestEntity> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => UserInterestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
