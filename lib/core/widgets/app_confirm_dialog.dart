import 'package:flutter/material.dart';
import 'app_snackbar.dart';

/// ===== DIALOG XÁC NHẬN DÙNG CHUNG CHO TOÀN APP =====
///
/// Thay thế các hàm _showDeleteConfirm gần như y hệt nhau ở:
/// vai_tro_sub, tai_khoan_sub, nhan_vien_page, customers_page,
/// danh_muc_sub, product_list_sub — mỗi nơi copy-paste lại cùng 1
/// AlertDialog (icon cảnh báo, RichText tên item in đậm, 2 nút Hủy/Xóa).
///
/// ----- Cách dùng cho XÓA (phổ biến nhất) -----
///   showAppDeleteConfirmDialog(
///     context: context,
///     itemLabel: 'vai trò',              // "Xóa vai trò "..."?"
///     itemName: role['tenVaiTro'],
///     extraWarning: 'Nếu có tài khoản đang dùng vai trò này, thao tác sẽ thất bại.',
///     onConfirm: () async {
///       final res = await http.delete(...);
///       if (res.statusCode == 200) {
///         await _fetchRoles();
///         AppSnackbar.success(context, 'Đã xóa vai trò "$name"');
///       } else {
///         throw Exception(jsonDecode(res.body)['message']);
///       }
///     },
///   );
///
/// ----- Cách dùng cho xác nhận chung (không phải xóa) -----
///   showAppConfirmDialog(
///     context: context,
///     title: 'Chưa lưu thay đổi',
///     message: 'Bạn có thay đổi chưa được lưu. Chuyển vai trò sẽ mất các thay đổi đó.',
///     confirmLabel: 'Bỏ thay đổi & chuyển',
///     confirmColor: Colors.orange,
///     onConfirm: () => setState(() { ... }),
///   );

/// Dialog xác nhận CHUNG (tiêu đề + nội dung tự do + 1 nút hành động).
/// [onConfirm] là hàm đồng bộ (không cần async/network) — dùng cho các
/// case như "cảnh báo mất dữ liệu chưa lưu".
Future<void> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Hủy',
  String confirmLabel = 'Xác nhận',
  Color confirmColor = Colors.redAccent,
  IconData titleIcon = Icons.warning_amber_rounded,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(titleIcon, color: confirmColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Ở lại', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Dialog xác nhận XÓA — mẫu chuyên biệt, style thống nhất cho mọi màn
/// hình có nút xóa (vai trò, tài khoản, nhân viên, khách hàng, sản phẩm,
/// danh mục...).
///
/// [itemLabel]: danh từ mô tả loại item, ví dụ 'vai trò', 'tài khoản',
/// 'nhân viên' — dùng để dựng câu "Xóa {itemLabel} "{itemName}"?".
/// [extraWarning]: câu cảnh báo phụ thêm sau dấu "?" (tùy chọn).
/// [onConfirm]: hàm async thực hiện gọi API xóa. Nếu ném Exception,
/// dialog sẽ tự hiển thị AppSnackbar.error với message của exception đó
/// (đã bóc "Exception: " ở đầu).
Future<void> showAppDeleteConfirmDialog({
  required BuildContext context,
  required String itemLabel,
  required String itemName,
  String? extraWarning,
  required Future<void> Function() onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 10),
          Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          children: [
            TextSpan(text: 'Xóa $itemLabel '),
            TextSpan(
              text: '"$itemName"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: extraWarning != null
                  ? '? $extraWarning'
                  : '? Thao tác này không thể hoàn tác.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              await onConfirm();
            } catch (e) {
              if (context.mounted) {
                AppSnackbar.error(context, AppSnackbar.cleanExceptionMessage(e));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
