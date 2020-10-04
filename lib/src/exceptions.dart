import 'package:meta/meta.dart';

/// an exception for quid errors
@immutable
class QuidException implements Exception {
  /// standard error
  final dynamic error;

  /// unauthorized
  final bool unauthorized;

  /// the message
  String get message => error?.toString() ?? '';

  /// unauthorized exception
  const QuidException.unauthorized()
      : this.unauthorized = true,
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
