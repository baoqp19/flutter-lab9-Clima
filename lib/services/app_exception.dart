enum RecoveryAction { appSettings, locationSettings }

/// Lỗi đã được chuyển thành thông báo có thể hiển thị cho người dùng.
class AppException implements Exception {
  const AppException(this.message, {this.action});

  final String message;
  final RecoveryAction? action;

  @override
  String toString() => message;
}
