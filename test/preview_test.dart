// Tạo ảnh xem trước bằng dữ liệu mô phỏng khi truyền WRITE_PREVIEWS=true.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clima/main.dart';
import 'package:clima/screens/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'weather_screen_test.dart' show FakeWeatherService;

void main() {
  if (!const bool.fromEnvironment('WRITE_PREVIEWS')) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        jsonDecode(await config.readAsString())['packages'] as List;
    final flutter =
        packages.firstWhere((dynamic p) => p['name'] == 'flutter') as Map;
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final fonts = sdk.uri.resolve('bin/cache/artifacts/material_fonts/');
    for (final entry in {
      'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf', 'roboto-light.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final name in entry.value) {
        loader.addFont(
          File.fromUri(fonts.resolve(name))
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      }
      await loader.load();
    }
  });

  for (final size in [const Size(390, 1550), const Size(1280, 900)]) {
    testWidgets('Xuất ảnh ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final service = FakeWeatherService();
      addTearDown(service.close);
      await tester.pumpWidget(const ClimaApp());
      final theme = Theme.of(tester.element(find.byType(WeatherScreen)));
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
            ),
            debugShowCheckedModeBanner: false,
            home: WeatherScreen(weatherService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/clima-${size.width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    });
  }
}
