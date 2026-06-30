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

  // ==========================================
  // 2. NƠI THÊM CÁC CÀI ĐẶT KHÁC SAU NÀY (VÍ DỤ)
  // ==========================================
  // static const String _kStoreName = 'store_name';
  // static Future<void> saveStoreName(String name) async => await _prefs.setString(_kStoreName, name);
  // static String getStoreName() => _prefs.getString(_kStoreName) ?? 'Tên cửa hàng mặc định';
}
