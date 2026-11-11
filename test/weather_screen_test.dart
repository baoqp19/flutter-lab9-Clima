import 'dart:async';

import 'package:clima/main.dart';
import 'package:clima/models/weather_model.dart';
import 'package:clima/screens/weather_screen.dart';
import 'package:clima/services/app_exception.dart';
import 'package:clima/services/location.dart';
import 'package:clima/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'weather_test.dart' show weatherJson;

class FakeWeatherService extends WeatherService {
  final calls = <String>[];
  Completer<WeatherModel>? pending;
  bool fail = false;

  @override
  bool get isConfigured => true;

  @override
  void ensureConfigured() {}

  @override
  Future<WeatherModel> byCity(String city) async {
    calls.add(city);
    if (pending != null) return pending!.future;
    if (fail) throw const AppException('Không tìm thấy thành phố.');
    return WeatherModel.fromJson(
      weatherJson(city: city == 'Hanoi,VN' ? 'Hà Nội' : city),
    );
  }

  @override
  Future<WeatherModel> byCoordinates(double latitude, double longitude) async {
    calls.add('$latitude,$longitude');
    return WeatherModel.fromJson(weatherJson(city: 'Vị trí GPS'));
  }
}

class FakeLocation extends LocationService {
  bool denied = false;

  @override
  Future<DeviceCoordinates> getCurrentLocation() async {
    if (denied) throw const AppException('Chưa có quyền vị trí.');
    return const DeviceCoordinates(10.8, 106.7);
  }
}

void main() {
  testWidgets('Chưa có API key hiển thị hướng dẫn và kiểm tra ô trống', (
    tester,
  ) async {
    await tester.pumpWidget(const ClimaApp());
    expect(find.text('Hôm nay, trời thế nào?'), findsOneWidget);
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pump();
    expect(find.text('Vui lòng nhập tên thành phố.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tìm thành phố, giữ dữ liệu cũ khi lỗi và thử lại', (
    tester,
  ) async {
    final service = FakeWeatherService();
    addTearDown(service.close);
    await tester.pumpWidget(
      MaterialApp(home: WeatherScreen(weatherService: service)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hà Nội, VN'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Da Nang');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Da Nang, VN'), findsOneWidget);
    service.fail = true;
    await tester.enterText(find.byType(TextFormField), 'missing');
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy thành phố.'), findsOneWidget);
    expect(find.text('Da Nang, VN'), findsOneWidget);
    service.fail = false;
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('missing, VN'), findsOneWidget);
    expect(find.text('Không tìm thấy thành phố.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS gọi thời tiết theo tọa độ và xử lý từ chối quyền', (
    tester,
  ) async {
    final service = FakeWeatherService();
    final location = FakeLocation();
    addTearDown(service.close);
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherScreen(weatherService: service, locationService: location),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(service.calls.last, '10.8,106.7');
    expect(find.text('Vị trí GPS, VN'), findsOneWidget);
    location.denied = true;
    await tester.tap(find.text('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có quyền vị trí.'), findsOneWidget);
    expect(find.text('Vị trí GPS, VN'), findsOneWidget);
  });

  testWidgets('Khóa nút khi tải, an toàn khi màn hình bị đóng', (tester) async {
    final service = FakeWeatherService()..pending = Completer<WeatherModel>();
    addTearDown(service.close);
    await tester.pumpWidget(
      MaterialApp(home: WeatherScreen(weatherService: service)),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Vị trí của tôi'),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    service.pending!.complete(WeatherModel.fromJson(weatherJson()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('Bố cục không tràn tại ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeWeatherService();
      addTearDown(service.close);
      await tester.pumpWidget(
        MaterialApp(home: WeatherScreen(weatherService: service)),
      );
      await tester.pumpAndSettle();
      expect(find.text('28°'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
