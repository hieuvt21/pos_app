import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter dùng CHUNG cho mọi ô nhập SỐ ĐIỆN THOẠI (VN, tối đa 10 số).
/// Hiển thị dạng "0912.345.678" (nhóm 4-3-3), giá trị gõ vào chỉ giữ chữ số.
/// Dùng cho: Nhân viên, Khách hàng, Tài khoản, v.v. sau này.
class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      // Chèn dấu chấm sau vị trí thứ 4 và thứ 7 -> nhóm 4-3-3
      if ((i == 3 || i == 6) && i != digits.length - 1) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter dùng CHUNG cho mọi ô nhập SỐ TIỀN, tự phân tách hàng nghìn.
/// (Trước đây định nghĩa riêng lẻ trong membership_tier_sub.dart, nay tách
/// ra đây để mọi trang dùng chung — lương, giá sản phẩm, hóa đơn...)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String numStr = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numStr.isEmpty) return newValue.copyWith(text: '');
    int value = int.parse(numStr);
    String newText = _formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Hàm dùng CHUNG: loại bỏ toàn bộ ký tự không phải số.
/// Dùng để lấy giá trị "sạch" trước khi gửi lên API/lưu DB.
/// Áp dụng được cho cả SĐT ("0912.345.678" -> "0912345678")
/// lẫn số tiền ("6,000,000" -> "6000000").
String formatPhoneDisplay(String? raw) {
  if (raw == null) return '-';

  final digits = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '-';

  final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
  if (limited.length <= 4) return limited;
  if (limited.length <= 7) {
    return '${limited.substring(0, 4)}.${limited.substring(4)}';
  }

  return '${limited.substring(0, 4)}.${limited.substring(4, 7)}.${limited.substring(7)}';
}

String stripNonDigits(String formattedText) {
  return formattedText.replaceAll(RegExp(r'[^0-9]'), '');
}
