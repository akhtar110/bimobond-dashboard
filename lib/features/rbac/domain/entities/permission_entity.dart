import 'package:equatable/equatable.dart';

class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.id,
    required this.key,
    required this.group,
    required this.label,
    this.description,
    required this.action,
    required this.createdAt,
  });

  final String id;
  final String key;
  final String group;
  final String label;
  final String? description;
  final String action;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    key,
    group,
    label,
    description,
    action,
    createdAt,
  ];
}
