import 'package:flutter/material.dart';

import 'screens/weather_screen.dart';

void main() => runApp(const ClimaApp());

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima • Thời tiết của bạn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6255C4)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF71758B), height: 1.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4E5EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4E5EF)),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
      home: const WeatherScreen(),
    );
  }
}
