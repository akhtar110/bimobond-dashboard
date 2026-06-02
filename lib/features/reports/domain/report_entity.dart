class ReportEntity {
  const ReportEntity({
    required this.id,
    required this.reason,
    required this.reporter,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String reason;
  final String reporter;
  final String targetType;
  final String targetId;
}
