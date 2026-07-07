import 'package:flutter/material.dart';

/// ===== INPUT DECORATION DÙNG CHUNG CHO TOÀN APP =====
///
/// Thay thế các hàm _inputDecoration / _dlgInputDecoration /
/// _dialogInputDecoration / _connInputDecoration đang được viết lại gần
/// như y hệt ở: vai_tro_sub, tai_khoan_sub, nhan_vien_page, login_page,
/// app_settings_sub, product_list_sub, customers_page, danh_muc_sub...
///
/// Cách dùng:
///   TextField(
///     controller: nameController,
///     decoration: appInputDecoration(
///       hint: 'VD: Nguyễn Văn A',
///       icon: Icons.badge_outlined,
///       focusColor: themeColor,
///       errorText: errorText,
///     ),
///   )
///
/// Biến thể "dense" (dùng trong các form nhỏ, bảng nhập liệu dày đặc như
/// product_list_sub) chỉ cần truyền thêm `dense: true`.
InputDecoration appInputDecoration({
  required String hint,
  required Color focusColor,
  IconData? icon,
  String? errorText,
  Widget? suffixIcon,
  bool dense = false,
  bool filled = true,
  Color fillColor = Colors.white,
}) {
  final borderRadius = BorderRadius.circular(8);
  final errorColor = Colors.red;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: const Color(0xFF94A3B8),
      fontSize: dense ? 11.5 : 13,
    ),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    filled: filled,
    fillColor: fillColor,
    isDense: dense,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: dense ? 8 : 10,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: errorText != null ? errorColor : const Color(0xFFE2E8F0),
      ),
      borderRadius: borderRadius,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: errorText != null ? errorColor : focusColor,
        width: 1.5,
      ),
      borderRadius: borderRadius,
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red),
      borderRadius: borderRadius,
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
      borderRadius: borderRadius,
    ),
  );
}

/// Nhãn label phía trên 1 ô nhập — thay cho các hàm _label / _dlgLabel
/// lặp lại y hệt (chỉ khác tên hàm) ở nhiều dialog.
Widget appFieldLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF475569),
    ),
  );
}

/// Tiêu đề khối/section trong 1 trang cài đặt (khung nền xám bo góc) —
/// thay cho _sectionTitle / _buildSectionTitle / _buildSectionHeader
/// đang được viết lại giống hệt nhau ở membership_tier_sub, zalo_oa_sub,
/// thong_tin_cua_hang_sub, product_list_sub.
Widget appSectionTitle(String title) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Color(0xFF334155),
        letterSpacing: 0.5,
      ),
    ),
  );
}
