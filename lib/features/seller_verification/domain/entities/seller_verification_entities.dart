import 'package:equatable/equatable.dart';

enum SellerVerificationStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  revoked('REVOKED');

  const SellerVerificationStatus(this.apiValue);
  final String apiValue;

  static SellerVerificationStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final upper = raw.toUpperCase();
    for (final value in SellerVerificationStatus.values) {
      if (value.apiValue == upper) return value;
    }
    return null;
  }
}

class SellerVerificationApplicationEntity extends Equatable {
  const SellerVerificationApplicationEntity({
    required this.id,
    required this.userId,
    required this.status,
    this.businessName,
    this.documentType,
    this.documentUrl,
    this.additionalNotes,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.user,
  });

  final String id;
  final String userId;
  final String status;
  final String? businessName;
  final String? documentType;
  final String? documentUrl;
  final String? additionalNotes;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic>? user;

  SellerVerificationStatus get verificationStatus =>
      SellerVerificationStatus.tryParse(status) ??
      SellerVerificationStatus.pending;

  bool get isPending => verificationStatus == SellerVerificationStatus.pending;

  String get displayName =>
      user?['username'] as String? ??
      user?['fullName'] as String? ??
      businessName ??
      userId;

  String? get avatarUrl => user?['avatarUrl'] as String?;

  /// Path id for admin approve/reject.
  ///
  /// Backend resolves the record by **user**
  /// (`PATCH /seller-verification/admin/:userId/approve|reject`),
  /// so this must be [userId], not the application row id.
  String get reviewTargetId {
    final uid = userId.trim();
    if (uid.isNotEmpty) return uid;
    return id.trim();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        status,
        businessName,
        documentType,
        documentUrl,
        additionalNotes,
        rejectionReason,
        submittedAt,
        reviewedAt,
        user,
      ];
}

class SellerVerificationPageEntity extends Equatable {
  const SellerVerificationPageEntity({
    required this.applications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<SellerVerificationApplicationEntity> applications;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasReachedMax => currentPage >= lastPage;

  @override
  List<Object?> get props => [applications, currentPage, lastPage, total];
}

class AdminSellerVerificationQuery extends Equatable {
  const AdminSellerVerificationQuery({
    this.search,
    this.status,
  });

  final String? search;
  final String? status;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int limit,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }
    final statusValue = status?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      params['status'] = statusValue;
    }
    return params;
  }

  @override
  List<Object?> get props => [search, status];
}
