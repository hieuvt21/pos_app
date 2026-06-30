import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static late final SharedPreferences _prefs;

  /// Hàm khởi tạo tổng - Chỉ chạy duy nhất 1 lần khi ứng dụng vừa mở lên
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==========================================
  // 0. HÀM DÙNG CHUNG (GENERIC STRING STORAGE)
  //    Dùng cho: jwt_token, user_name, v.v.
  // ==========================================
  static String? getString(String key) => _prefs.getString(key);

  static Future<void> setRawString(String key, String value) async =>
      await _prefs.setString(key, value);

  // ==========================================
  // 1. CẤU HÌNH HẠNG THÀNH VIÊN (MEMBERSHIP)
  // ==========================================
  static const String _kMembershipTiers = 'membership_tiers_data';
  static const String _kTierDiscountEnabled = 'is_tier_discount_enabled';

  static Future<void> saveMembershipTiers(String jsonStr) async =>
      await _prefs.setString(_kMembershipTiers, jsonStr);

  static String? getMembershipTiers() => _prefs.getString(_kMembershipTiers);

  static Future<void> saveTierDiscountStatus(bool enabled) async =>
      await _prefs.setBool(_kTierDiscountEnabled, enabled);

  static bool getTierDiscountStatus() =>
      _prefs.getBool(_kTierDiscountEnabled) ?? false;

  // 3. CẤU HÌNH HỆ THỐNG (MÁY CHỦ & GIAO DIỆN)
  // ==========================================
  static const String _kServerIp = 'server_ip';
  static const String _kServerPort = 'server_port';
  static const String _kAppTheme = 'app_theme_mode';

  // IP Server
  static Future<void> saveServerIp(String ip) async =>
      await _prefs.setString(_kServerIp, ip);
  static String? getServerIp() => _prefs.getString(_kServerIp);

  // Port Server
  static Future<void> saveServerPort(String port) async =>
      await _prefs.setString(_kServerPort, port);
  static String? getServerPort() => _prefs.getString(_kServerPort);

  // Tên Theme (Lưu theo enum name)
  static Future<void> saveAppTheme(String themeName) async =>
      await _prefs.setString(_kAppTheme, themeName);
  static String? getAppTheme() => _prefs.getString(_kAppTheme);
}
