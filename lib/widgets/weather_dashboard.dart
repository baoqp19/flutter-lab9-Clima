import 'package:flutter/material.dart';

import '../models/weather_model.dart';

class WeatherDashboard extends StatelessWidget {
  const WeatherDashboard({super.key, required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hero = _currentWeather();
      final details = _details();
      if (constraints.maxWidth >= 820) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: hero),
            const SizedBox(width: 24),
            Expanded(flex: 5, child: details),
          ],
        );
      }
      return Column(children: [hero, const SizedBox(height: 24), details]);
    },
  );

  Widget _currentWeather() {
    final time = weather.localObservation;
    final stamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${time.day}/${time.month}/${time.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: weather.isNight
              ? const [Color(0xFF343963), Color(0xFF5D5490)]
              : const [Color(0xFF8170D6), Color(0xFF5B59AC)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6255C4).withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THỜI TIẾT HIỆN TẠI',
            style: TextStyle(
              color: Color(0xFFE2DCF9),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  weather.country.isEmpty
                      ? weather.city
                      : '${weather.city}, ${weather.country}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${weather.temperature.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 100,
                        fontWeight: FontWeight.w300,
                        height: 1.1,
                        letterSpacing: -5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  weather.icon,
                  size: constraints.maxWidth < 300 ? 68 : 96,
                  color: const Color(0xFFFFDE94),
                  semanticLabel: weather.description,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            weather.description,
            style: const TextStyle(color: Colors.white, fontSize: 21),
          ),
          const SizedBox(height: 8),
          Text(
            'Cảm giác như ${weather.feelsLike.round()}°C',
            style: const TextStyle(color: Color(0xFFE2DCF9)),
          ),
          const SizedBox(height: 30),
          const Divider(color: Color(0xFF9A8FCE)),
          const SizedBox(height: 12),
          Text(
            'Quan trắc lúc $stamp',
            style: const TextStyle(color: Color(0xFFE2DCF9), fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Giờ địa phương tại thành phố',
            style: TextStyle(color: Color(0xFFCFC8EF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Một góc nhìn chi tiết',
        style: TextStyle(
          color: Color(0xFF252840),
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 14) / 2;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _metric(
                width,
                Icons.thermostat_rounded,
                'Cảm nhận',
                '${weather.feelsLike.round()}°C',
                const Color(0xFFF4AD83),
              ),
              _metric(
                width,
                Icons.water_drop_outlined,
                'Độ ẩm',
                '${weather.humidity}%',
                const Color(0xFF79AEE5),
              ),
              _metric(
                width,
                Icons.air_rounded,
                'Tốc độ gió',
                '${weather.windSpeed.toStringAsFixed(1)} m/s',
                const Color(0xFF7BBEAB),
              ),
              _metric(
                width,
                Icons.speed_rounded,
                'Áp suất',
                '${weather.pressure} hPa',
                const Color(0xFFAB92D5),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEAF8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF7964B5),
              size: 23,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Một lời nhắc nhỏ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF514178),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    weather.advice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF766591),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _metric(
    double width,
    IconData icon,
    String label,
    String value,
    Color color,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEEEF5)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Color(0xFF303149),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
