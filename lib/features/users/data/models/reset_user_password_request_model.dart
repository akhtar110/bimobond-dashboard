class ResetUserPasswordRequestModel {
  const ResetUserPasswordRequestModel({required this.newPassword});

  final String newPassword;

  Map<String, dynamic> toJson() => {'newPassword': newPassword};
}
