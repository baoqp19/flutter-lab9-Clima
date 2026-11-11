# Clima — Weather App

Ứng dụng Flutter học tích hợp OpenWeatherMap, xử lý JSON và GPS. Giao diện tiếng Việt, Material 3, tự điều chỉnh bố cục điện thoại và màn hình rộng.

## Chạy ứng dụng

Yêu cầu Flutter 3.47.1 / Dart 3.13.1 hoặc bản tương thích mới hơn. Android cần Android SDK; iOS cần macOS và Xcode. Dự án có sẵn nền tảng Android, iOS và web.

1. Tạo tài khoản và lấy API key tại [OpenWeatherMap](https://home.openweathermap.org/api_keys). Key cần quyền dùng Current Weather và Geocoding API; key mới có thể cần thời gian kích hoạt.
2. Cài dependencies và tạo cấu hình cục bộ:

   ```powershell
   flutter pub get
   Copy-Item config/env.example.json config/env.json
   ```

3. Thay `YOUR_OPENWEATHER_API_KEY` trong `config/env.json` bằng key của bạn.
4. Chạy trên thiết bị đã kết nối hoặc trình giả lập:

   ```powershell
   flutter run --dart-define-from-file=config/env.json
   ```

   Hoặc chạy trình duyệt:

   ```powershell
   flutter emulators --launch Pixel_10
   flutter run -d emulator-5554 --dart-define-from-file=config/env.json
   ```

Có thể truyền trực tiếp bằng `flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY`. Khi thay key, dừng và chạy lại ứng dụng. Không có key, ứng dụng hiển thị hướng dẫn cấu hình; không dùng dữ liệu giả thay cho thời tiết thực.

`config/env.json` đã được bỏ qua trong Git. `dart-define` giúp tách cấu hình khỏi mã nguồn nhưng không bảo mật key bên trong bản build; khi phát hành sản phẩm, nên chuyển việc gọi API qua backend do bạn quản lý.

## Chức năng và cách sử dụng

- Khi có key, ứng dụng tải thời tiết Hà Nội lúc khởi động. Không tự xin quyền GPS.
- Nhập thành phố và nhấn Enter/nút mũi tên, hoặc chọn một thành phố gợi ý.
- Có thể thêm mã quốc gia để tránh trùng tên, ví dụ `London,GB`. Ứng dụng chọn kết quả geocoding đầu tiên.
- Nhấn **Vị trí của tôi** để xin quyền và lấy thời tiết tại vị trí hiện tại.
- Hiển thị nhiệt độ °C, mô tả tiếng Việt, thành phố, biểu tượng theo mã thời tiết/ngày đêm, nhiệt độ cảm nhận, độ ẩm, tốc độ gió m/s và áp suất hPa.
- Mốc quan trắc dùng giờ địa phương của thành phố, lấy từ `dt` và `timezone` trong API, không lấy giờ thiết bị.
- Nhấn nút làm mới hoặc kéo xuống để cập nhật lại tọa độ đang hiển thị. Nhấn **Vị trí của tôi** lần nữa nếu đã di chuyển.
- Hiển thị tiến trình khi tải; khóa thao tác để tránh gọi trùng. Khi lỗi, giữ dữ liệu thành công trước đó kèm thông báo rõ ràng và nút thử lại.
- Xử lý tên rỗng, thành phố không tồn tại, key sai, quá giới hạn API, timeout, mất mạng, JSON không hợp lệ, GPS tắt và quyền vị trí bị từ chối.

## Cấu trúc để tìm hiểu

```text
lib/
  main.dart                       MaterialApp và theme Material 3
  screens/weather_screen.dart     StatefulWidget, tìm kiếm, GPS, tải/lỗi, setState
  widgets/weather_dashboard.dart  Nhiệt độ, biểu tượng và các chỉ số
  models/weather_model.dart       Chuyển JSON thành dữ liệu có kiểu
  services/
    app_exception.dart            Thông báo lỗi và hành động khắc phục
    networking.dart               HTTP, timeout, mã phản hồi, giải mã UTF-8/JSON
    location.dart                 Kiểm tra GPS, xin quyền và lấy tọa độ
    weather_service.dart          Geocoding và Current Weather API
config/env.example.json           Cấu hình mẫu, không chứa key thật
test/                             Kiểm tra dịch vụ và tương tác giao diện
```

Luồng thành phố: `TextField → WeatherService.byCity → Geocoding API → tọa độ → Current Weather API → WeatherModel.fromJson → setState → giao diện mới`.

Luồng GPS: `nút vị trí → LocationService → kiểm tra dịch vụ/quyền → tọa độ → WeatherService.byCoordinates → giao diện`.

`http` thực hiện request HTTPS, `geolocator` lấy vị trí. Chỉ báo tải dùng widget Material có sẵn nên không cần `flutter_spinkit`. Các lớp dịch vụ nhận dependency qua constructor để kiểm thử bằng dữ liệu mô phỏng.

## Cấu hình vị trí theo nền tảng

- **Android:** đã khai báo `INTERNET` và `ACCESS_COARSE_LOCATION` trong manifest chính để bản release cũng có mạng. Độ chính xác gần đúng đủ để lấy thời tiết; ứng dụng không yêu cầu vị trí nền. `compileSdk` dùng cấu hình SDK Flutter hiện tại (geolocator yêu cầu tối thiểu 35).
- **iOS:** đã có `NSLocationWhenInUseUsageDescription` trong `Info.plist` và `BYPASS_PERMISSION_LOCATION_ALWAYS=1` trong Podfile theo hướng dẫn [geolocator](https://pub.dev/packages/geolocator#ios). Chỉ yêu cầu quyền khi sử dụng ứng dụng. Cấu hình CocoaPods, deployment target iOS 15; bản iOS cần kiểm tra trên máy Mac.
- **Web:** GPS cần HTTPS hoặc localhost cùng quyền vị trí trình duyệt. Nếu không mở được cài đặt hệ thống bằng nút trong ứng dụng, xem hướng dẫn trong thông báo và cấp quyền tại trình duyệt. Tìm thành phố vẫn hoạt động khi không cấp quyền vị trí.
- **Giả lập:** thiết lập tọa độ giả lập trong phần điều khiển vị trí của emulator/simulator để thử GPS.

Trên Windows, dự án và Pub cache có thể nằm ở hai ổ đĩa khác nhau. `android/gradle.properties` đã tắt Kotlin incremental compilation để tránh lỗi cache đường dẫn khác ổ; có thể bật lại nếu môi trường không gặp lỗi này. Xem [cấu hình Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html#incremental-compilation).

## Kiểm tra và build

```powershell
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/env.json
flutter build apk --debug --dart-define-from-file=config/env.json
```

Các bài test dùng HTTP và GPS mô phỏng, không cần key, không gọi dịch vụ thật. Bao gồm request thành phố/tọa độ, JSON/UTF-8, lỗi mạng/API, icon thời tiết, tìm kiếm, thử lại, quyền GPS và bố cục 360/1280 px.

Có thể xuất ảnh giao diện bằng dữ liệu mô phỏng (không phải thời tiết thật): `flutter test test/preview_test.dart --dart-define=WRITE_PREVIEWS=true`. Ảnh nằm tại `build/previews/`.

## Tài liệu API

- [Current Weather](https://openweathermap.org/current): endpoint `/data/2.5/weather`, `units=metric`, `lang=vi`.
- [Geocoding](https://openweathermap.org/api/geocoding-api): endpoint `/geo/1.0/direct`; dùng riêng vì bộ geocoder tích hợp cũ đã bị ngừng phát triển.
- [http](https://pub.dev/packages/http) và [geolocator](https://pub.dev/packages/geolocator).
