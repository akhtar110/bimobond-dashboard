import '../../domain/entities/seller_verification_entities.dart';

class SellerVerificationApplicationModel
    extends SellerVerificationApplicationEntity {
  const SellerVerificationApplicationModel({
    required super.id,
    required super.userId,
    required super.status,
    super.businessName,
    super.documentType,
    super.documentUrl,
    super.additionalNotes,
    super.rejectionReason,
    required super.submittedAt,
    super.reviewedAt,
    super.user,
  });

  factory SellerVerificationApplicationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final map = Map<String, dynamic>.from(json);
    final userRaw = map['user'];
    final nestedRaw = map['application'] ?? map['sellerVerification'];
    final nested = nestedRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(nestedRaw)
        : null;

    final userId = _firstNonEmpty([
      map['userId'],
      map['user_id'],
      userRaw is Map ? userRaw['id'] : null,
      // Some list payloads are user-centric (top-level id == user id).
      if (nested != null) map['id'],
    ]);

    final topLevelId = _firstNonEmpty([map['id']]);
    // Prefer nested application id; avoid treating user id as application id.
    final applicationId = _firstNonEmpty([
      nested?['id'],
      nested?['applicationId'],
      map['applicationId'],
      if (topLevelId.isNotEmpty && topLevelId != userId) topLevelId,
    ]);

    return SellerVerificationApplicationModel(
      id: applicationId.isNotEmpty ? applicationId : userId,
      userId: userId.isNotEmpty ? userId : applicationId,
      status: _firstNonEmpty([
            map['status'],
            map['verificationStatus'],
            nested?['status'],
          ]).isNotEmpty
          ? _firstNonEmpty([
              map['status'],
              map['verificationStatus'],
              nested?['status'],
            ])
          : 'PENDING',
      businessName: _nullableString(map['businessName']) ??
          _nullableString(nested?['businessName']),
      documentType: _nullableString(map['documentType']) ??
          _nullableString(nested?['documentType']),
      documentUrl: _nullableString(map['documentUrl']) ??
          _nullableString(map['documentImageUrl']) ??
          _nullableString(nested?['documentUrl']) ??
          _nullableString(nested?['documentImageUrl']),
      additionalNotes: _nullableString(map['additionalNotes']) ??
          _nullableString(map['notes']) ??
          _nullableString(nested?['additionalNotes']) ??
          _nullableString(nested?['notes']),
      rejectionReason: _nullableString(map['rejectionReason']) ??
          _nullableString(nested?['rejectionReason']),
      submittedAt: _date(
        map['submittedAt'] ??
            map['createdAt'] ??
            nested?['submittedAt'] ??
            nested?['createdAt'],
      ),
      reviewedAt: _nullableDate(map['reviewedAt'] ?? nested?['reviewedAt']),
      user: userRaw is Map
          ? Map<String, dynamic>.from(userRaw)
          : null,
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class SellerVerificationPageModel extends SellerVerificationPageEntity {
  const SellerVerificationPageModel({
    required super.applications,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  factory SellerVerificationPageModel.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['data'] ?? json['applications'] ?? json['items']) as List?;

    final applications = (rawList ?? [])
        .map(
          (e) => SellerVerificationApplicationModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;
    final lastPage = (meta['totalPages'] as num?)?.toInt() ??
        (meta['lastPage'] as num?)?.toInt() ??
        1;
    final total = (meta['total'] as num?)?.toInt() ?? applications.length;

    return SellerVerificationPageModel(
      applications: applications,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}
