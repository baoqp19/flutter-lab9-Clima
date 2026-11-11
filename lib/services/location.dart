import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'app_exception.dart';

class DeviceCoordinates {
  const DeviceCoordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class LocationService {
  Future<DeviceCoordinates> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException(
          'Dịch vụ vị trí đang tắt. Hãy bật vị trí hoặc tìm theo thành phố.',
          action: RecoveryAction.locationSettings,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'Quyền vị trí đã bị chặn. Bạn có thể cấp lại quyền trong cài đặt.',
          action: RecoveryAction.appSettings,
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const AppException(
          'Chưa có quyền vị trí. Bạn vẫn có thể tìm theo thành phố.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return DeviceCoordinates(position.latitude, position.longitude);
    } on TimeoutException {
      throw const AppException(
        'Chưa xác định được vị trí. Hãy thử lại hoặc nhập thành phố.',
      );
    } on PermissionDeniedException {
      throw const AppException(
        'Quyền vị trí bị từ chối. Hãy tìm theo thành phố.',
      );
    } on LocationServiceDisabledException {
      throw const AppException(
        'Hãy bật dịch vụ vị trí rồi thử lại.',
        action: RecoveryAction.locationSettings,
      );
    } on PlatformException {
      throw const AppException(
        'Không lấy được vị trí trên thiết bị này. Hãy tìm theo thành phố.',
      );
    } on UnsupportedError {
      throw const AppException(
        'Trình duyệt này chưa hỗ trợ vị trí. Hãy tìm theo thành phố.',
      );
    }
  }

  Future<bool> openSettings(RecoveryAction action) =>
      action == RecoveryAction.appSettings
      ? Geolocator.openAppSettings()
      : Geolocator.openLocationSettings();
}
