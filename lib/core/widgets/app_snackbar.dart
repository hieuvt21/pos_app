import 'package:flutter/material.dart';

/// ===== SNACKBAR DÙNG CHUNG CHO TOÀN APP =====
///
/// Thay thế các hàm _showSnack / _showSnackBar / _showCustomSnackBar /
/// _showSnackBarSimple đang bị lặp lại (với vài biến thể nhỏ khác nhau)
/// ở rất nhiều trang: vai_tro_sub, tai_khoan_sub, nhan_vien_page,
/// customers_page, zalo_oa_sub, app_settings_sub, login_page, v.v.
///
/// Cách dùng:
///   AppSnackbar.success(context, 'Đã lưu thành công!');
///   AppSnackbar.error(context, 'Lỗi kết nối API: $e');
///   AppSnackbar.warning(context, 'Vui lòng nhập đầy đủ thông tin');
///   AppSnackbar.info(context, 'Đang tải dữ liệu...');
///
/// Nếu cần màu tùy chỉnh (ví dụ theo màu hạng thành viên):
///   AppSnackbar.show(context, 'Nội dung', backgroundColor: myColor, icon: Icons.star);
class AppSnackbar {
  AppSnackbar._();

  /// Hàm gốc — mọi hàm success/error/warning/info bên dưới đều gọi lại hàm này.
  static void show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    IconData? icon,
    bool floating = true,
  }) {
    if (!context.mounted) return;

    final content = icon == null
        ? Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
        : Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: content,
          backgroundColor: backgroundColor,
          //behavior: floating ? SnackBarBehavior.floating : null,
          //margin: floating ? const EdgeInsets.all(16) : null,
        ),
      );
  }

  /// Thông báo thành công. Mặc định dùng màu chủ đề (colorScheme.primary)
  /// vì đa số các trang hiện tại đang dùng màu theme động cho việc này.
  /// Truyền [color] nếu muốn ép cứng màu xanh lá (VD: 0xFF10B981).
  static void success(
    BuildContext context,
    String message, {
    Color? color,
    IconData icon = Icons.check_circle_rounded,
    bool withIcon = true,
  }) {
    show(
      context,
      message,
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      icon: withIcon ? icon : null,
    );
  }

  /// Thông báo lỗi — luôn màu đỏ.
  static void error(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_outline_rounded,
    bool withIcon = true,
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      icon: withIcon ? icon : null,
    );
  }

  /// Thông báo cảnh báo — màu cam.
  static void warning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    bool withIcon = true,
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: withIcon ? icon : null,
    );
  }

  /// Thông báo thông tin chung — màu xám trung tính.
  static void info(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    bool withIcon = true,
  }) {
    show(
      context,
      message,
      backgroundColor: const Color(0xFF64748B),
      icon: withIcon ? icon : null,
    );
  }

  /// Tiện ích: bóc thông báo lỗi ra khỏi "Exception: ..." — dùng khi
  /// catch (e) rồi muốn hiển thị message gọn, giống pattern đang lặp lại
  /// ở rất nhiều dialog: e.toString().replaceAll('Exception: ', '')
  static String cleanExceptionMessage(Object e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}
