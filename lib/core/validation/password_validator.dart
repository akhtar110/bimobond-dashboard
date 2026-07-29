/// Shared password rules for admin reset and other flows.
/// Backend contract for admin reset: 6–128 characters.
/// Client keeps letter / number / special hints from the existing UI.
abstract final class PasswordValidator {
  static const int minLength = 6;
  static const int maxLength = 128;

  static final RegExp _letterPattern = RegExp(r'[A-Za-z]');
  static final RegExp _numberPattern = RegExp(r'\d');
  static final RegExp _specialPattern = RegExp(r'[!@#\$%^&*]');

  static bool hasMinLength(String value) => value.length >= minLength;

  static bool hasMaxLength(String value) => value.length <= maxLength;

  static bool hasLetter(String value) => _letterPattern.hasMatch(value);

  static bool hasNumber(String value) => _numberPattern.hasMatch(value);

  static bool hasSpecialCharacter(String value) =>
      _specialPattern.hasMatch(value);

  static bool hasValidLength(String value) =>
      hasMinLength(value) && hasMaxLength(value);

  /// Backend accepts any 6–128 char string; UI still encourages stronger passwords.
  static bool isValid(String value) =>
      hasValidLength(value) &&
      hasLetter(value) &&
      hasNumber(value) &&
      hasSpecialCharacter(value);

  /// Strict backend-only length check.
  static bool meetsBackendContract(String value) => hasValidLength(value);
}
