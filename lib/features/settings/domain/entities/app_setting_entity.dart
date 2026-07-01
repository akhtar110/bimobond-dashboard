import 'package:equatable/equatable.dart';

class AppSettingEntity extends Equatable {
  const AppSettingEntity({
    required this.key,
    required this.value,
    this.description,
  });

  final String key;
  final String value;
  final String? description;

  @override
  List<Object?> get props => [key, value, description];
}
