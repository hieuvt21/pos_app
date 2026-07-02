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

  // ==========================================
  // 4. CẤU HÌNH THÔNG TIN CỬA HÀNG & ỨNG DỤNG
  // ==========================================
  static const String _kAppName = 'app_name_config';
  static const String _kAppWindowIcon = 'app_window_icon_config';
  static const String _kWidgetTitle = 'widget_title_config';
  static const String _kWidgetIcon = 'widget_icon_config';

  static const String _kShopName = 'shop_name_config';
  static const String _kShopPhone = 'shop_phone_config';
  static const String _kShopAddress = 'shop_address_config';
  static const String _kShopEmail = 'shop_email_config';
  static const String _kShopLogo = 'shop_logo_config';
  static const String _kShopTaxCode =
      'shop_tax_code_config'; // Mã số thuế (Đề xuất thêm)
  static const String _kShopWebsite =
      'shop_website_config'; // Website (Đề xuất thêm)
  static const String _kInvoiceFooter =
      'invoice_footer_config'; // Lời chúc hóa đơn (Đề xuất thêm)

  // Getters & Setters cho cấu hình APP
  static String getAppName() => _prefs.getString(_kAppName) ?? "RJ Code POS";
  static Future<void> saveAppName(String val) async =>
      await _prefs.setString(_kAppName, val);

  static String getAppWindowIcon() =>
      _prefs.getString(_kAppWindowIcon) ?? "storefront_rounded";
  static Future<void> saveAppWindowIcon(String val) async =>
      await _prefs.setString(_kAppWindowIcon, val);

  static String getWidgetTitle() =>
      _prefs.getString(_kWidgetTitle) ?? "Phần mềm Pos TJ";
  static Future<void> saveWidgetTitle(String val) async =>
      await _prefs.setString(_kWidgetTitle, val);

  static String getWidgetIcon() =>
      _prefs.getString(_kWidgetIcon) ?? "storefront_rounded";
  static Future<void> saveWidgetIcon(String val) async =>
      await _prefs.setString(_kWidgetIcon, val);

  // Getters & Setters cho cấu hình CỬA HÀNG
  static String getShopName() => _prefs.getString(_kShopName) ?? "";
  static Future<void> saveShopName(String val) async =>
      await _prefs.setString(_kShopName, val);

  static String getShopPhone() => _prefs.getString(_kShopPhone) ?? "";
  static Future<void> saveShopPhone(String val) async =>
      await _prefs.setString(_kShopPhone, val);

  static String getShopAddress() => _prefs.getString(_kShopAddress) ?? "";
  static Future<void> saveShopAddress(String val) async =>
      await _prefs.setString(_kShopAddress, val);

  static String getShopEmail() => _prefs.getString(_kShopEmail) ?? "";
  static Future<void> saveShopEmail(String val) async =>
      await _prefs.setString(_kShopEmail, val);

  static String getShopLogo() => _prefs.getString(_kShopLogo) ?? "";
  static Future<void> saveShopLogo(String val) async =>
      await _prefs.setString(_kShopLogo, val);

  static String getShopTaxCode() => _prefs.getString(_kShopTaxCode) ?? "";
  static Future<void> saveShopTaxCode(String val) async =>
      await _prefs.setString(_kShopTaxCode, val);

  static String getShopWebsite() => _prefs.getString(_kShopWebsite) ?? "";
  static Future<void> saveShopWebsite(String val) async =>
      await _prefs.setString(_kShopWebsite, val);

  static String getInvoiceFooter() =>
      _prefs.getString(_kInvoiceFooter) ?? "Cảm ơn quý khách. Hẹn gặp lại!";
  static Future<void> saveInvoiceFooter(String val) async =>
      await _prefs.setString(_kInvoiceFooter, val);
}
