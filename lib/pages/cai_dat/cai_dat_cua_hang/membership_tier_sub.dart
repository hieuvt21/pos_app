import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Bộ định dạng tự động thêm dấu phẩy phân tách phần nghìn khi người dùng gõ số
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Xóa tất cả các ký tự không phải là số trước khi định dạng lại
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

class MembershipTierSubPage extends StatefulWidget {
  const MembershipTierSubPage({super.key});

  @override
  State<MembershipTierSubPage> createState() => _MembershipTierSubPageState();
}

class _MembershipTierSubPageState extends State<MembershipTierSubPage> {
  bool _isTierDiscountEnabled = false;

  // Cấu trúc danh sách quản lý theo khoảng (Từ -> Đến) cùng hệ thống Icon định danh
  final List<Map<String, dynamic>> _membershipTiers = [
    {
      'tier': 'Bạc',
      'icon': Icons.stars_rounded,
      'iconColor': const Color(0xFF94A3B8),
      'from': '5,000,000',
      'to': '15,000,000',
      'discount': '2%',
    },
    {
      'tier': 'Vàng',
      'icon': Icons.stars_rounded,
      'iconColor': const Color(0xFFEAB308),
      'from': '15,000,000',
      'to': '30,000,000',
      'discount': '5%',
    },
    {
      'tier': 'Bạch kim',
      'icon': Icons.stars_rounded,
      'iconColor': const Color(0xFFEAB308),
      'from': '15,000,000',
      'to': '30,000,000',
      'discount': '5%',
    },
    {
      'tier': 'Kim Cương',
      'icon': Icons.stars_rounded,
      'iconColor': const Color(0xFF06B6D4),
      'from': '30,000,000',
      'to': 'Trở lên',
      'discount': '10%',
    },
    {
      'tier': 'VIP',
      'icon': Icons.stars_rounded,
      'iconColor': const Color(0xFF06B6D4),
      'from': '30,000,000',
      'to': 'Trở lên',
      'discount': '10%',
    },
  ];

  // Hàm mở Dialog chỉnh sửa cấu hình cho từng hạng
  void _showEditTierDialog(Map<String, dynamic> tierData, Color themeColor) {
    final TextEditingController fromController = TextEditingController(
      text: tierData['from'],
    );
    final TextEditingController toController = TextEditingController(
      text: tierData['to'],
    );
    final TextEditingController discountController = TextEditingController(
      text: tierData['discount'].replaceAll('%', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(tierData['icon'], color: tierData['iconColor'], size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Tooltip(
                  message: 'Cập nhật ${tierData['tier']}',
                  child: Text(
                    'Cập nhật ${tierData['tier']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mức chi tiêu tối thiểu (Từ)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: fromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: _inputDecoration('Nhập số tiền', themeColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mức chi tiêu tối đa (Đến)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: toController,
                  decoration: _inputDecoration(
                    'Nhập số tiền hoặc "Trở lên"',
                    themeColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mức chiết khấu (%)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Ví dụ: 5', themeColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã cập nhật cấu hình cho ${tierData['tier']}',
                    ),
                    backgroundColor: themeColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER TIÊU ĐỀ SUB-PAGE =================
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership_rounded,
                        color: dynamicThemeColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Quản lý Hạng Thành Viên & Chiết Khấu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thiết lập hạn mức chi tiêu tích lũy bắt buộc (VNĐ) để hệ thống tự động nâng cấp bậc thành viên cho khách hàng, kèm cấu hình kích hoạt chính sách ưu đãi.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F5F9)),

                  // ================= SWITCH CÀI ĐẶT NHANH =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tự động chiết khấu hóa đơn theo hạng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Khi bật, hệ thống POS sẽ tự động áp dụng giảm giá trực tiếp % vào hóa đơn của khách hàng khi thanh toán dựa theo phân hạng Bạc (2%), Vàng (5%), Kim cương (10%).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Switch(
                          value: _isTierDiscountEnabled,
                          activeThumbColor: dynamicThemeColor,
                          activeTrackColor: dynamicThemeColor.withValues(
                            alpha: 0.4,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isTierDiscountEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ================= BẢNG DANH SÁCH HẠNG (TABLE UI) =================
                  const Text(
                    'Danh sách phân hạng thành viên hiện tại',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.8),
                        1: FlexColumnWidth(2.0),
                        2: FlexColumnWidth(2.0),
                        3: FlexColumnWidth(1.4),
                        4: FlexColumnWidth(1.2),
                      },
                      // ĐÃ SỬA LỖI: Sử dụng defaultVerticalAlignment thay cho verticalAlignment trực tiếp
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        // Tiêu đề bảng
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          children: [
                            _buildTableCell('HẠNG THÀNH VIÊN', isHeader: true),
                            _buildTableCell('TỪ (VNĐ)', isHeader: true),
                            _buildTableCell('ĐẾN (VNĐ)', isHeader: true),
                            _buildTableCell('CHIẾT KHẤU', isHeader: true),
                            _buildTableCell('HÀNH ĐỘNG', isHeader: true),
                          ],
                        ),
                        // Nội dung dữ liệu các hàng
                        ..._membershipTiers.map((tier) {
                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      tier['icon'],
                                      color: tier['iconColor'],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      // KHẮC PHỤC: Thêm Tooltip khi hover hiển thị đầy đủ thông tin tên hạng
                                      child: Tooltip(
                                        message: tier['tier'],
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF1E293B,
                                          ).withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          tier['tier'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF334155),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildTableCell(tier['from']),
                              _buildTableCell(tier['to']),
                              _buildTableCell(
                                tier['discount'],
                                isDiscount: true,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Center(
                                  child: IconButton(
                                    onPressed: () => _showEditTierDialog(
                                      tier,
                                      dynamicThemeColor,
                                    ),
                                    icon: Icon(
                                      Icons.edit_note_rounded,
                                      color: dynamicThemeColor,
                                      size: 22,
                                    ),
                                    tooltip: 'Chỉnh sửa cấu hình',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  // ================= ĐÁY TRANG - THANH NÚT BẤM =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isTierDiscountEnabled = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hủy thay đổi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Đã cập nhật cấu hình hạng thành viên thành công!',
                                  ),
                                ],
                              ),
                              backgroundColor: dynamicThemeColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dynamicThemeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lưu cấu hình',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      // KHẮC PHỤC: Thêm Tooltip khi hover hiển thị đầy đủ thông tin các cột tiền/chiết khấu
      child: Tooltip(
        message: text,
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeader ? 11 : 13,
            fontWeight: (isHeader || isDiscount)
                ? FontWeight.bold
                : FontWeight.w500,
            color: isHeader
                ? const Color(0xFF64748B)
                : (isDiscount
                      ? const Color(0xFF10B981)
                      : const Color(0xFF475569)),
            letterSpacing: isHeader ? 0.5 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
