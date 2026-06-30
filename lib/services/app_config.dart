// lib/services/app_config.dart
import 'package:flutter/material.dart';
import '../pages/cai_dat/app_storage.dart'; // Đảm bảo đúng đường dẫn tới file AppStorage của bạn

class AppConfig extends ChangeNotifier {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  // Thuộc tính lưu trữ IP và Port cục bộ trong Class
  late String _serverIp;
  late String _serverPort;

  AppConfig._internal() {
    // KHỞI TẠO BAN ĐẦU: Ưu tiên đọc lại cấu hình cũ từ bộ nhớ máy (thông qua AppStorage)
    // Nếu chưa từng lưu (lần đầu mở app), sẽ lấy giá trị mặc định ban đầu.
    _serverIp = AppStorage.getServerIp() ?? '192.168.0.150';
    _serverPort = AppStorage.getServerPort() ?? '5000';
  }

  String get serverIp => _serverIp;
  String get serverPort => _serverPort;

  String get baseUrl => 'http://$_serverIp:$_serverPort';

  String buildUrl(String segment) {
    final cleanSegment = segment.startsWith('/')
        ? segment.substring(1)
        : segment;
    return '$baseUrl/$cleanSegment';
  }

  /// Hàm cập nhật cấu hình và lưu vĩnh viễn vào thiết bị
  void updateConfig(String ip, String port) async {
    _serverIp = ip.trim();
    _serverPort = port.trim();

    // LƯU VĨNH VIỄN: Ghi trực tiếp xuống SharedPreferences thông qua AppStorage
    await AppStorage.saveServerIp(_serverIp);
    await AppStorage.saveServerPort(_serverPort);

    // Phát tín hiệu cập nhật UI tới toàn bộ các trang đang lắng nghe (như AppSettingsSubPage)
    notifyListeners();
  }
}
