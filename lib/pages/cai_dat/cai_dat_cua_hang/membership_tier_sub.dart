import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../app_storage.dart';

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

class MembershipTierSubPage extends StatefulWidget {
  const MembershipTierSubPage({super.key});

  @override
  State<MembershipTierSubPage> createState() => _MembershipTierSubPageState();
}

class _MembershipTierSubPageState extends State<MembershipTierSubPage> {
  bool _isTierDiscountEnabled = false;
  bool _isLoading = true;

  // Dữ liệu mẫu ban đầu (UI tĩnh tách biệt)
  List<Map<String, dynamic>> _membershipTiers = [
    {
      'id': 'silver',
      'tier': 'Hạng Bạc (Silver)',
      'threshold': '5,000,000',
      'discount': '2%',
    },
    {
      'id': 'gold',
      'tier': 'Hạng Vàng (Gold)',
      'threshold': '15,000,000',
      'discount': '5%',
    },
    {
      'id': 'platinum_new',
      'tier': 'Hạng Bạch Kim (Platinum)',
      'threshold': '30,000,000',
      'discount': '7%',
    },
    {
      'id': 'diamond',
      'tier': 'Hạng Kim Cương (Diamond)',
      'threshold': '50,000,000',
      'discount': '10%',
    },
    {
      'id': 'vip',
      'tier': 'Hạng VIP',
      'threshold': '100,000,000',
      'discount': '15%',
    },
  ];

  Color _getTierColor(String id) {
    switch (id) {
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'gold':
        return const Color(0xFFEAB308);
      case 'platinum_new':
        return const Color(0xFF6366F1);
      case 'diamond':
        return const Color(0xFF06B6D4);
      case 'vip':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDataFromDisk();
  }

  // TỐI ƯU: Đọc dữ liệu tập trung qua AppStorage thông qua RAM, cực nhanh và không cần await SharedPreferences
  void _loadDataFromDisk() {
    try {
      _isTierDiscountEnabled = AppStorage.getTierDiscountStatus();
      String? cachedTiers = AppStorage.getMembershipTiers();
      if (cachedTiers != null) {
        List<dynamic> decodedList = jsonDecode(cachedTiers);
        _membershipTiers = decodedList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (e) {
      debugPrint("Lỗi đọc dữ liệu: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // TỐI ƯU: Gọi hàm save thông qua AppStorage
  Future<void> _saveDataToDisk() async {
    await AppStorage.saveTierDiscountStatus(_isTierDiscountEnabled);
    await AppStorage.saveMembershipTiers(jsonEncode(_membershipTiers));
  }

  int _parseAmount(String value) {
    String cleanStr = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanStr.isEmpty) return 0;
    return int.parse(cleanStr);
  }

  void _showEditTierDialog(
    int index,
    Map<String, dynamic> tierData,
    Color themeColor,
  ) {
    final TextEditingController thresholdController = TextEditingController(
      text: tierData['threshold'],
    );
    final TextEditingController discountController = TextEditingController(
      text: tierData['discount'].replaceAll('%', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? errorText;
            bool isValid = true;
            int currentThreshold = _parseAmount(thresholdController.text);

            if (index > 0) {
              int prevThreshold = _parseAmount(
                _membershipTiers[index - 1]['threshold'],
              );
              if (currentThreshold <= prevThreshold) {
                errorText =
                    'Mốc chi tiêu phải lớn hơn ${_membershipTiers[index - 1]['tier']} (${_membershipTiers[index - 1]['threshold']})';
                isValid = false;
              }
            }

            if (index < _membershipTiers.length - 1) {
              int nextThreshold = _parseAmount(
                _membershipTiers[index + 1]['threshold'],
              );
              if (currentThreshold >= nextThreshold) {
                errorText =
                    'Mốc chi tiêu phải nhỏ hơn ${_membershipTiers[index + 1]['tier']} (${_membershipTiers[index + 1]['threshold']})';
                isValid = false;
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: _getTierColor(tierData['id'] ?? ''),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cập nhật ${tierData['tier']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      'Mức chi tiêu tối thiểu để đạt hạng (VNĐ)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: thresholdController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: _inputDecoration(
                        'Nhập số tiền tối thiểu',
                        themeColor,
                        errorText: errorText,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mức chiết khấu (%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
                  onPressed: isValid
                      ? () {
                          setState(() {
                            _membershipTiers[index]['threshold'] =
                                thresholdController.text.trim();
                            _membershipTiers[index]['discount'] =
                                '${discountController.text.trim()}%';
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? themeColor : Colors.grey[300],
                    foregroundColor: isValid ? Colors.white : Colors.grey[500],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    'Khách hàng tích lũy tổng chi tiêu đạt mức tối thiểu dưới đây sẽ được hệ thống phân bậc tương ứng.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F5F9)),
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
                                'Tự động áp dụng giảm giá trực tiếp % vào hóa đơn dựa theo phân hạng thành viên khi thanh toán.',
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3.0),
                        1: FlexColumnWidth(2.5),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.2),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          children: [
                            _buildTableCell(
                              'TÊN BẬC THÀNH VIÊN',
                              isHeader: true,
                            ),
                            _buildTableCell(
                              'MỨC TÍCH LŨY TỐI THIỂU (VNĐ)',
                              isHeader: true,
                            ),
                            _buildTableCell('CHIẾT KHẤU', isHeader: true),
                            _buildTableCell('CHỈNH SỬA', isHeader: true),
                          ],
                        ),
                        ...List.generate(_membershipTiers.length, (index) {
                          final tier = _membershipTiers[index];
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
                                      Icons.stars_rounded,
                                      color: _getTierColor(tier['id'] ?? ''),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
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
                                  ],
                                ),
                              ),
                              _buildTableCell(tier['threshold']),
                              _buildTableCell(
                                tier['discount'],
                                isDiscount: true,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Center(
                                  child: IconButton(
                                    onPressed: () => _showEditTierDialog(
                                      index,
                                      tier,
                                      dynamicThemeColor,
                                    ),
                                    icon: Icon(
                                      Icons.edit_note_rounded,
                                      color: dynamicThemeColor,
                                      size: 22,
                                    ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _loadDataFromDisk();
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
                        onPressed: () async {
                          await _saveDataToDisk();
                          if (context.mounted) {
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
                                      'Cấu hình hạng thành viên đã được lưu trữ vĩnh viễn!',
                                    ),
                                  ],
                                ),
                                backgroundColor: dynamicThemeColor,
                              ),
                            );
                          }
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
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    Color focusColor, {
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : focusColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
