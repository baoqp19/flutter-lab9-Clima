import 'dart:async';
import 'dart:convert';

import 'package:clima/models/weather_model.dart';
import 'package:clima/services/app_exception.dart';
import 'package:clima/services/networking.dart';
import 'package:clima/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> weatherJson({
  String city = 'Hà Nội',
  int condition = 800,
}) => {
  'name': city,
  'sys': {'country': 'VN'},
  'coord': {'lat': 21.02, 'lon': 105.84},
  'main': {'temp': 28.4, 'feels_like': 30.2, 'humidity': 74, 'pressure': 1008},
  'wind': {'speed': 3.6},
  'weather': [
    {'id': condition, 'description': 'bầu trời quang đãng', 'icon': '01d'},
  ],
  'dt': 1704067200,
  'timezone': 25200,
};

void main() {
  test('Đọc JSON UTF-8, đơn vị và giờ của thành phố', () async {
    final requests = <Uri>[];
    final service = WeatherService(
      apiKey: 'test-key',
      network: NetworkHelper(
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path == '/geo/1.0/direct') {
            return http.Response('[{"lat":21.02,"lon":105.84}]', 200);
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode(weatherJson())),
            200,
          );
        }),
      ),
    );
    addTearDown(service.close);
    final weather = await service.byCity(' Hà Nội,VN ');
    expect(requests.first.queryParameters['q'], 'Hà Nội,VN');
    expect(requests.last.queryParameters, containsPair('units', 'metric'));
    expect(requests.last.queryParameters, containsPair('lang', 'vi'));
    expect(requests.last.queryParameters, containsPair('lat', '21.02'));
    expect(weather.city, 'Hà Nội');
    expect(weather.temperature, 28.4);
    expect(weather.description, 'Bầu trời quang đãng');
    expect(weather.localObservation.hour, 7);
  });

  test('Thiếu key hoặc tên thành phố không phát sinh HTTP', () async {
    var calls = 0;
    final network = NetworkHelper(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(network.close);
    await expectLater(
      WeatherService(apiKey: '', network: network).byCity('Hanoi'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      WeatherService(apiKey: 'key', network: network).byCity('  '),
      throwsA(isA<AppException>()),
    );
    expect(calls, 0);
  });

  for (final entry in {
    401: 'API key',
    429: 'giới hạn',
    500: 'gián đoạn',
  }.entries) {
    test('Thông báo lỗi HTTP ${entry.key}', () async {
      final network = NetworkHelper(
        client: MockClient((_) async => http.Response('{}', entry.key)),
      );
      addTearDown(network.close);
      await expectLater(
        network.getJson(Uri.https('example.com')),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains(entry.value),
          ),
        ),
      );
    });
  }

  for (final payload in ['[]', '{}', '[{"lat":"invalid","lon":1}]']) {
    test('Không cập nhật thời tiết khi geocoding trả $payload', () async {
      var calls = 0;
      final service = WeatherService(
        apiKey: 'key',
        network: NetworkHelper(
          client: MockClient((_) async {
            calls++;
            return http.Response(payload, 200);
          }),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.byCity('missing'),
        throwsA(isA<AppException>()),
      );
      expect(calls, 1);
    });
  }

  for (final payload in ['not json', '{}', '[]', '{"weather":[]}']) {
    test('Xử lý JSON hỏng hoặc thiếu dữ liệu: $payload', () async {
      final service = WeatherService(
        apiKey: 'key',
        network: NetworkHelper(
          client: MockClient((_) async => http.Response(payload, 200)),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.byCoordinates(1, 2),
        throwsA(isA<AppException>()),
      );
    });
  }

  test('Chuyển mất mạng và timeout thành thông báo', () async {
    for (final error in [
      http.ClientException('offline'),
      TimeoutException('timeout'),
    ]) {
      final network = NetworkHelper(
        client: MockClient((_) async => throw error),
      );
      addTearDown(network.close);
      await expectLater(
        network.getJson(Uri.https('example.com')),
        throwsA(isA<AppException>()),
      );
    }
  });

  test('Biểu tượng thay đổi theo mã thời tiết và đêm', () {
    expect(
      WeatherModel.fromJson(weatherJson(condition: 200)).icon,
      Icons.thunderstorm_rounded,
    );
    expect(
      WeatherModel.fromJson(weatherJson(condition: 501)).icon,
      Icons.water_drop_rounded,
    );
    expect(
      WeatherModel.fromJson(weatherJson(condition: 601)).icon,
      Icons.ac_unit_rounded,
    );
    expect(
      WeatherModel.fromJson(weatherJson(condition: 741)).icon,
      Icons.blur_on_rounded,
    );
    expect(
      WeatherModel.fromJson(weatherJson(condition: 803)).icon,
      Icons.cloud_rounded,
    );
    final night = weatherJson();
    (night['weather'] as List).first['icon'] = '01n';
    expect(WeatherModel.fromJson(night).icon, Icons.nightlight_round);
  });
}
