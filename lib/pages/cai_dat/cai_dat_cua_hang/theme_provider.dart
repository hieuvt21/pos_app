import 'package:flutter/material.dart';

/// Định nghĩa các bộ chủ đề màu sắc có sẵn trong hệ thống
enum AppThemeMode {
  indigo(name: 'Xanh Indigo (Mặc định)', color: Color(0xFF6366F1)),
  blue(name: 'Xanh Dương', color: Color(0xFF2563EB)),
  emerald(name: 'Xanh Lá', color: Color(0xFF10B981)),
  rose(name: 'Hồng Quý Phái', color: Color(0xFFF43F5E)),
  orange(name: 'Cam Năng Động', color: Color(0xFFEA580C)),
  violet(name: 'Tím Sang Trọng', color: Color(0xFF8B5CF6));

  final String name;
  final Color color;
  const AppThemeMode({required this.name, required this.color});
}

/// Lớp trung tâm quản lý trạng thái giao diện toàn bộ ứng dụng
class AppThemeProvider extends ChangeNotifier {
  // Singleton Pattern để dễ dàng gọi ở mọi trang
  static final AppThemeProvider _instance = AppThemeProvider._internal();
  factory AppThemeProvider() => _instance;
  AppThemeProvider._internal();

  // Chủ đề mặc định ban đầu là Xanh Indigo
  AppThemeMode _currentTheme = AppThemeMode.indigo;
  AppThemeMode get currentTheme => _currentTheme;

  // Trạng thái chế độ tối (Mặc định là Sáng)
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  /// Hàm thay đổi chủ đề màu sắc
  void changeTheme(AppThemeMode newTheme) {
    if (_currentTheme != newTheme) {
      _currentTheme = newTheme;
      notifyListeners();
    }
  }

  /// Hàm bật/tắt chế độ tối (Dark Mode)
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Kích hoạt làm mới giao diện lập tức
  }

  /// Hàm sinh dữ liệu ThemeData chuẩn Material 3 dựa theo màu chủ đạo và chế độ sáng/tối
  ThemeData getThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.color,
        primary: _currentTheme.color,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        // Nếu là chế độ tối, chuyển nền sang màu tối, ngược lại giữ màu trắng phẳng
        surface: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      ),
      // Cấu hình chung cho toàn bộ Input/TextField trong app
      inputDecorationTheme: InputDecorationTheme(
        fillColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
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
