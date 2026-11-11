import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../services/app_exception.dart';
import '../services/location.dart';
import '../services/weather_service.dart';
import '../widgets/weather_dashboard.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, this.weatherService, this.locationService});

  final WeatherService? weatherService;
  final LocationService? locationService;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final WeatherService _service;
  late final LocationService _location;
  WeatherModel? _weather;
  AppException? _error;
  bool _loading = false;
  Future<WeatherModel> Function()? _lastRequest;

  @override
  void initState() {
    super.initState();
    _service = widget.weatherService ?? WeatherService();
    _location = widget.locationService ?? LocationService();
    if (_service.isConfigured) {
      _load(() => _service.byCity('Hanoi,VN'));
    }
  }

  Future<void> _load(Future<WeatherModel> Function() request) async {
    if (_loading) return;
    _lastRequest = request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weather = await request();
      if (mounted) setState(() => _weather = weather);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const AppException(
            'Chưa tải được thời tiết. Vui lòng thử lại hoặc tìm thành phố khác.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search([String? city]) {
    if (_loading) return;
    if (city != null) _cityController.text = city;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final query = _cityController.text.trim();
    _load(() => _service.byCity(query));
  }

  void _locate() => _load(() async {
    _service.ensureConfigured();
    final position = await _location.getCurrentLocation();
    return _service.byCoordinates(position.latitude, position.longitude);
  });

  Future<void> _refresh() async {
    final weather = _weather;
    if (weather != null) {
      await _load(
        () => _service.byCoordinates(weather.latitude, weather.longitude),
      );
    } else if (_lastRequest != null) {
      await _load(_lastRequest!);
    }
  }

  Future<void> _openSettings() async {
    final action = _error?.action;
    if (action == null) return;
    var opened = false;
    try {
      opened = await _location.openSettings(action);
    } catch (_) {
      // Web không mở được cài đặt hệ thống bằng API native.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy mở cài đặt thiết bị hoặc quyền vị trí của trình duyệt, sau đó nhấn Vị trí của tôi.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    if (widget.weatherService == null) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 42),
                    const Text(
                      'Thời tiết quanh bạn',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Color(0xFF252840),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Một chút thời tiết, một ngày chủ động.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    _searchBar(),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final city in const {
                          'Hà Nội': 'Hanoi,VN',
                          'TP. Hồ Chí Minh': 'Ho Chi Minh City,VN',
                          'Đà Nẵng': 'Da Nang,VN',
                          'London': 'London,GB',
                        }.entries)
                          ActionChip(
                            avatar: const Icon(
                              Icons.location_city_rounded,
                              size: 16,
                            ),
                            label: Text(city.key),
                            onPressed: _loading
                                ? null
                                : () => _search(city.value),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE7E7F0)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_loading) ...[
                      const LinearProgressIndicator(
                        semanticsLabel: 'Đang tải thời tiết',
                        minHeight: 3,
                      ),
                      const SizedBox(height: 12),
                      const Text('Đang cập nhật thời tiết…'),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      _errorCard(),
                      const SizedBox(height: 20),
                    ],
                    if (_weather != null)
                      WeatherDashboard(weather: _weather!)
                    else if (!_loading)
                      _welcome(),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Dữ liệu từ OpenWeatherMap  •  Nhiệt độ °C',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF6255C4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.wb_sunny_rounded,
          color: Color(0xFFFFD782),
          size: 25,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'clima',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: Color(0xFF252840),
        ),
      ),
      const Spacer(),
      IconButton.filledTonal(
        onPressed: _loading || (_weather == null && _lastRequest == null)
            ? null
            : _refresh,
        tooltip: 'Làm mới thời tiết',
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );

  Widget _searchBar() => Form(
    key: _formKey,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final field = TextFormField(
          controller: _cityController,
          enabled: !_loading,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _search(),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập tên thành phố.'
              : null,
          decoration: InputDecoration(
            hintText: 'Tìm thành phố…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Tìm kiếm',
              onPressed: _loading ? null : () => _search(),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        );
        final location = FilledButton.tonalIcon(
          onPressed: _loading ? null : _locate,
          icon: const Icon(Icons.my_location_rounded, size: 20),
          label: const Text('Vị trí của tôi'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
        if (constraints.maxWidth < 550) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [field, const SizedBox(height: 12), location],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            location,
          ],
        );
      },
    ),
  );

  Widget _errorCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EC),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFAD4930)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chưa cập nhật được thời tiết',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAD4930),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_error!.message, style: const TextStyle(color: Color(0xFF854F42))),
        if (_weather != null) ...[
          const SizedBox(height: 8),
          const Text('Bên dưới là dữ liệu của lần cập nhật thành công trước.'),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _loading ? null : () => _load(_lastRequest!),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
            if (_error!.action != null)
              TextButton(
                onPressed: _openSettings,
                child: const Text('Mở cài đặt'),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _welcome() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFECE8FC), Color(0xFFE9F1FC)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        const Icon(Icons.wb_cloudy_rounded, size: 88, color: Color(0xFF8172CA)),
        const SizedBox(height: 20),
        const Text(
          'Hôm nay, trời thế nào?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF353052),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _service.isConfigured
              ? 'Tìm một thành phố hoặc dùng vị trí hiện tại để bắt đầu.'
              : 'Kết nối API key OpenWeatherMap theo README,\nsau đó tìm thành phố hoặc dùng vị trí của bạn.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    ),
  );
}
