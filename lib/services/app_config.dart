// lib/services/app_config.dart
import 'package:flutter/material.dart';

class AppConfig extends ChangeNotifier {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // SỬA TẠI ĐÂY: Đổi từ '192.168.1.2' sang IP máy chủ hiện tại của bạn
  String _serverIp = '192.168.0.150';
  String _serverPort = '5000';

  String get serverIp => _serverIp;
  String get serverPort => _serverPort;

  String get baseUrl => 'http://$_serverIp:$_serverPort';

  String buildUrl(String segment) {
    final cleanSegment = segment.startsWith('/')
        ? segment.substring(1)
        : segment;
    return '$baseUrl/$cleanSegment';
  }

  void updateConfig(String ip, String port) {
    _serverIp = ip.trim();
    _serverPort = port.trim();
    notifyListeners(); // Phát tín hiệu cập nhật UI tới các trang đang lắng nghe
  }
}
