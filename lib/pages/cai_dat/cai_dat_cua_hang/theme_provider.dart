import 'package:flutter/material.dart';

enum AppThemeMode {
  indigo(
    name: 'Xanh Indigo (Mặc định)',
    color: Color(0xFF6366F1),
    isDark: false,
  ),
  blue(name: 'Xanh Dương', color: Color(0xFF2563EB), isDark: false),
  emerald(name: 'Xanh Lá', color: Color(0xFF10B981), isDark: false),
  rose(name: 'Hồng Quý Phái', color: Color(0xFFF43F5E), isDark: false),
  orange(name: 'Cam Năng Động', color: Color(0xFFEA580C), isDark: false),
  violet(name: 'Tím Sang Trọng', color: Color(0xFF8B5CF6), isDark: false),
  // ===== CÁC THEME TỐI MÀU MỚI =====
  midnight(name: 'Xanh Than Đêm (Tối)', color: Color(0xFF3B82F6), isDark: true),
  charcoal(name: 'Xám Than Chì (Tối)', color: Color(0xFF94A3B8), isDark: true),
  wine(name: 'Đỏ Rượu Vang (Tối)', color: Color(0xFFEF4444), isDark: true),
  forestDark(
    name: 'Lục Rừng Sâu (Tối)',
    color: Color(0xFF10B981),
    isDark: true,
  );

  final String name;
  final Color color;
  final bool isDark; // Theme tự quyết định sáng/tối, không cần toggle riêng
  const AppThemeMode({
    required this.name,
    required this.color,
    required this.isDark,
  });
}

class AppThemeProvider extends ChangeNotifier {
  static final AppThemeProvider _instance = AppThemeProvider._internal();
  factory AppThemeProvider() => _instance;
  AppThemeProvider._internal();

  AppThemeMode _currentTheme = AppThemeMode.indigo;
  AppThemeMode get currentTheme => _currentTheme;

  // Độ tối/sáng được suy ra trực tiếp từ theme đang chọn
  bool get isDarkMode => _currentTheme.isDark;

  void changeTheme(AppThemeMode newTheme) {
    if (_currentTheme != newTheme) {
      _currentTheme = newTheme;
      notifyListeners();
    }
  }

  ThemeData getThemeData() {
    final bool dark = _currentTheme.isDark;
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.color,
        primary: _currentTheme.color,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: dark ? const Color(0xFF0F172A) : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: dark ? const Color(0xFF1E293B) : Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _currentTheme.color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
