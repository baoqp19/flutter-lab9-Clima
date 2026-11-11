import 'package:flutter/material.dart';

class WeatherModel {
  const WeatherModel({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.description,
    required this.conditionId,
    required this.isNight,
    required this.observedAt,
    required this.timezoneOffset,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final String description;
  final int conditionId;
  final bool isNight;
  final DateTime observedAt;
  final int timezoneOffset;
  final double latitude;
  final double longitude;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      final main = json['main'] as Map<String, dynamic>;
      final conditions =
          (json['weather'] as List).first as Map<String, dynamic>;
      final coordinates = json['coord'] as Map<String, dynamic>;
      final sys = json['sys'] as Map<String, dynamic>;
      final description = conditions['description'] as String;
      return WeatherModel(
        city: (json['name'] as String?) ?? 'Vị trí hiện tại',
        country: (sys['country'] as String?) ?? '',
        temperature: (main['temp'] as num).toDouble(),
        feelsLike: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toInt(),
        windSpeed: ((json['wind'] as Map)['speed'] as num).toDouble(),
        pressure: (main['pressure'] as num).toInt(),
        description: description.isEmpty
            ? 'Thời tiết hiện tại'
            : '${description[0].toUpperCase()}${description.substring(1)}',
        conditionId: (conditions['id'] as num).toInt(),
        isNight: (conditions['icon'] as String).endsWith('n'),
        observedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as num).toInt() * 1000,
          isUtc: true,
        ),
        timezoneOffset: (json['timezone'] as num).toInt(),
        latitude: (coordinates['lat'] as num).toDouble(),
        longitude: (coordinates['lon'] as num).toDouble(),
      );
    } catch (_) {
      throw const FormatException(
        'Thiếu hoặc sai định dạng dữ liệu thời tiết.',
      );
    }
  }

  DateTime get localObservation =>
      observedAt.add(Duration(seconds: timezoneOffset));

  IconData get icon => switch (conditionId) {
    < 300 => Icons.thunderstorm_rounded,
    < 600 => Icons.water_drop_rounded,
    < 700 => Icons.ac_unit_rounded,
    < 800 => Icons.blur_on_rounded,
    800 => isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
    _ => Icons.cloud_rounded,
  };

  String get advice => switch (conditionId) {
    < 300 => 'Có giông ngoài trời. Hãy ưu tiên ở nơi an toàn.',
    < 600 => 'Nhớ mang theo một chiếc ô trước khi ra ngoài nhé.',
    < 700 => 'Trời có tuyết. Giữ ấm và chú ý khi di chuyển nhé.',
    < 800 => 'Tầm nhìn có thể hạn chế. Chú ý khi di chuyển nhé.',
    _ when temperature >= 32 =>
      'Trời khá nóng. Nhớ uống nước và chống nắng nhé.',
    _ when temperature < 18 =>
      'Trời se lạnh. Mang thêm một chiếc áo khoác nhé.',
    _ => 'Dành một chút thời gian tận hưởng ngày hôm nay nhé.',
  };
}
