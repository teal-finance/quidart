import 'package:meta/meta.dart';

/// an exception for quid errors
@immutable
class QuidException implements Exception {
  /// standard error
  final dynamic error;

  /// unauthorized
  final bool unauthorized;

  /// the user has no refresh token
  final bool hasToLogin;

  /// the message
  String get message => error?.toString() ?? '';

  /// unauthorized exception
  const QuidException.unauthorized()
      : this.unauthorized = true,
        this.hasToLogin = false,
        this.error = "Unauthorized";

  /// the user has to get a refresh token
  const QuidException.hasToLogin()
      : this.unauthorized = true,
        this.hasToLogin = true,
        this.error = "Too many retries";

  /// unauthorized exception
  const QuidException.tooManyRetries()
      : this.unauthorized = false,
        this.hasToLogin = false,
        this.error = "Unauthorized";

  @override
  String toString() {
    var msg = 'QuidError: $message';
    if (error is Error) {
      msg += '\n${error.stackTrace}';
    }
    return msg;
  }
}
