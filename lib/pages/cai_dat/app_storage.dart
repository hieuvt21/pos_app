import 'dart:async';

/// Lightweight in-memory fallback for SharedPreferences to avoid a hard
/// dependency on the shared_preferences package in environments where it's
/// not available. The API mirrors only what this app uses.
class AppStorage {
  static final Map<String, Object> _store = {};

  /// No-op init to keep the same call-site usage as before.
  static Future<void> init() async {}

  // ==========================================
  // 1. CẤU HÌNH HẠNG THÀNH VIÊN (MEMBERSHIP)
  // ==========================================
  static const String _kMembershipTiers = 'membership_tiers_data';
  static const String _kTierDiscountEnabled = 'is_tier_discount_enabled';

  static Future<void> saveMembershipTiers(String jsonStr) async {
    _store[_kMembershipTiers] = jsonStr;
  }

  static String? getMembershipTiers() => _store[_kMembershipTiers] as String?;

  static Future<void> saveTierDiscountStatus(bool enabled) async {
    _store[_kTierDiscountEnabled] = enabled;
  }

  static bool getTierDiscountStatus() =>
      (_store[_kTierDiscountEnabled] as bool?) ?? false;

  // ==========================================
  // 2. NƠI THÊM CÁC CÀI ĐẶT KHÁC SAU NÀY (VÍ DỤ)
  // ==========================================
  // static const String _kStoreName = 'store_name';
  // static Future<void> saveStoreName(String name) async => _store[_kStoreName] = name;
  // static String getStoreName() => _store[_kStoreName] as String? ?? 'Tên cửa hàng mặc định';
}
