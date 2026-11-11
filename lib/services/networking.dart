import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_exception.dart';

class NetworkHelper {
  NetworkHelper({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Object?> getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw AppException(switch (response.statusCode) {
          401 => 'API key chưa hợp lệ hoặc chưa được kích hoạt. Hãy kiểm tra cấu hình OpenWeatherMap.',
          404 => 'Không tìm thấy thành phố. Hãy thử tên khác hoặc thêm mã quốc gia, ví dụ London,GB.',
          429 => 'Đã vượt giới hạn gọi API. Vui lòng thử lại sau ít phút.',
          _ => 'Dịch vụ thời tiết đang gián đoạn. Vui lòng thử lại sau.',
        });
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const AppException(
        'Kết nối quá lâu. Kiểm tra mạng và thử lại nhé.',
      );
    } on http.ClientException {
      throw const AppException(
        'Không thể kết nối. Kiểm tra Internet và thử lại nhé.',
      );
    } on FormatException {
      throw const AppException(
        'Dữ liệu thời tiết không hợp lệ. Vui lòng thử lại sau.',
      );
    }
  }

  void close() => _client.close();
}
