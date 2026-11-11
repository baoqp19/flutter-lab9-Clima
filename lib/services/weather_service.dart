import '../models/weather_model.dart';
import 'app_exception.dart';
import 'networking.dart';

class WeatherService {
  WeatherService({String? apiKey, NetworkHelper? network})
    : _apiKey = (apiKey ?? const String.fromEnvironment('OPENWEATHER_API_KEY'))
          .trim(),
      _network = network ?? NetworkHelper();

  final String _apiKey;
  final NetworkHelper _network;

  bool get isConfigured => _apiKey.isNotEmpty;

  void ensureConfigured() {
    if (!isConfigured) {
      throw const AppException(
        'Chưa cấu hình API key. Hãy làm theo hướng dẫn trong README để kết nối OpenWeatherMap.',
      );
    }
  }

  Future<WeatherModel> byCity(String city) async {
    ensureConfigured();
    final query = city.trim();
    if (query.isEmpty) {
      throw const AppException('Hãy nhập tên thành phố bạn muốn tìm.');
    }
    // Geocoding riêng thay cho bộ geocoder cũ của Current Weather API.
    final data = await _network.getJson(
      Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
        'q': query,
        'limit': '1',
        'appid': _apiKey,
      }),
    );
    if (data is! List) {
      throw const AppException(
        'Dữ liệu địa điểm không hợp lệ. Vui lòng thử lại.',
      );
    }
    if (data.isEmpty) {
      throw const AppException(
        'Không tìm thấy thành phố. Thử tên khác hoặc thêm mã quốc gia, ví dụ London,GB.',
      );
    }
    final place = data.first;
    if (place is! Map || place['lat'] is! num || place['lon'] is! num) {
      throw const AppException(
        'Dữ liệu tọa độ không hợp lệ. Vui lòng thử lại.',
      );
    }
    return byCoordinates(
      (place['lat'] as num).toDouble(),
      (place['lon'] as num).toDouble(),
    );
  }

  Future<WeatherModel> byCoordinates(double latitude, double longitude) async {
    ensureConfigured();
    final data = await _network.getJson(
      Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': '$latitude',
        'lon': '$longitude',
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'vi',
      }),
    );
    try {
      if (data is! Map<String, dynamic>) throw const FormatException();
      return WeatherModel.fromJson(data);
    } on FormatException {
      throw const AppException(
        'Dữ liệu thời tiết không đầy đủ. Vui lòng thử lại sau.',
      );
    }
  }

  void close() => _network.close();
}
