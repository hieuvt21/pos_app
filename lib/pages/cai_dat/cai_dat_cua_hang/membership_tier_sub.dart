import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_storage.dart';
import '../../utils/membership_tier_utils.dart';
import '/pages/utils/input_formatters.dart';

class MembershipTierSubPage extends StatefulWidget {
  const MembershipTierSubPage({super.key});

  @override
  State<MembershipTierSubPage> createState() => _MembershipTierSubPageState();
}

class _MembershipTierSubPageState extends State<MembershipTierSubPage> {
  bool _isTierDiscountEnabled = false;
  bool _isLoading = true;

  // Dữ liệu các hạng thành viên (tên, mốc chi tiêu, chiết khấu, icon, màu sắc).
  // Giá trị khởi tạo lấy từ buildDefaultMembershipTiers() trong membership_tier_utils.dart
  // — dùng CHUNG với trang Khách hàng để đảm bảo đồng bộ.
  List<Map<String, dynamic>> _membershipTiers = buildDefaultMembershipTiers();

  @override
  void initState() {
    super.initState();
    _loadDataFromDisk();
  }

  // Đọc dữ liệu tập trung qua AppStorage. Nếu dữ liệu cũ (lưu trước khi có
  // tính năng chọn icon/màu) còn thiếu 2 trường này, tự động bổ sung dựa
  // theo 'id' để không bị lỗi hiển thị hoặc mất icon.
  void _loadDataFromDisk() {
    try {
      _isTierDiscountEnabled = AppStorage.getTierDiscountStatus();
      String? cachedTiers = AppStorage.getMembershipTiers();
      final defaults = buildDefaultMembershipTiers();

      if (cachedTiers != null && cachedTiers.isNotEmpty) {
        List<dynamic> decodedList = jsonDecode(cachedTiers);
        _membershipTiers = decodedList.map((item) {
          final tier = Map<String, dynamic>.from(item);
          final matchedDefault = defaults.firstWhere(
            (d) => d['id'] == tier['id'],
            orElse: () => defaults.first,
          );
          if (tier['icon'] == null || (tier['icon'] as String).isEmpty) {
            tier['icon'] = matchedDefault['icon'];
          }
          if (tier['colorHex'] == null ||
              (tier['colorHex'] as String).isEmpty) {
            tier['colorHex'] = matchedDefault['colorHex'];
          }
          return tier;
        }).toList();
      } else {
        _membershipTiers = defaults;
      }
    } catch (e) {
      debugPrint("Lỗi đọc dữ liệu: $e");
      _membershipTiers = buildDefaultMembershipTiers();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Gọi hàm save thông qua AppStorage
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
    final TextEditingController nameController = TextEditingController(
      text: tierData['tier'],
    );
    final TextEditingController thresholdController = TextEditingController(
      text: tierData['threshold'],
    );
    final TextEditingController discountController = TextEditingController(
      text: tierData['discount'].toString().replaceAll('%', ''),
    );
    String selectedIcon = tierData['icon'] ?? 'stars_rounded';
    String selectedColorHex = tierData['colorHex'] ?? '94A3B8';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? thresholdErrorText;
            String? nameErrorText;
            bool isValid = true;

            int currentThreshold = _parseAmount(thresholdController.text);

            if (index > 0) {
              int prevThreshold = _parseAmount(
                _membershipTiers[index - 1]['threshold'],
              );
              if (currentThreshold <= prevThreshold) {
                thresholdErrorText =
                    'Mốc chi tiêu phải lớn hơn ${_membershipTiers[index - 1]['tier']} (${_membershipTiers[index - 1]['threshold']})';
                isValid = false;
              }
            }

            if (index < _membershipTiers.length - 1) {
              int nextThreshold = _parseAmount(
                _membershipTiers[index + 1]['threshold'],
              );
              if (currentThreshold >= nextThreshold) {
                thresholdErrorText =
                    'Mốc chi tiêu phải nhỏ hơn ${_membershipTiers[index + 1]['tier']} (${_membershipTiers[index + 1]['threshold']})';
                isValid = false;
              }
            }

            if (nameController.text.trim().isEmpty) {
              nameErrorText = 'Tên hạng không được để trống';
              isValid = false;
            }

            final previewColor = tierColorFromHex(selectedColorHex);

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(tierIconFromKey(selectedIcon), color: previewColor, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cập nhật Hạng Thành Viên',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tên hạng thành viên',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: _inputDecoration(
                          'VD: Hạng Vàng (Gold)',
                          themeColor,
                          errorText: nameErrorText,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          errorText: thresholdErrorText,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration('Ví dụ: 5', themeColor),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Icon hiển thị',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tierIconCatalog.keys.map((key) {
                          final data = tierIconCatalog[key]!;
                          final isSelected = key == selectedIcon;
                          return Tooltip(
                            message: data['label'],
                            child: InkWell(
                              onTap: () =>
                                  setDialogState(() => selectedIcon = key),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? previewColor.withValues(alpha: 0.15)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? previewColor
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Icon(
                                  data['icon'],
                                  size: 20,
                                  color: isSelected
                                      ? previewColor
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Màu sắc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tierColorPalette.map((hex) {
                          final color = tierColorFromHex(hex);
                          final isSelected = hex == selectedColorHex;
                          return InkWell(
                            onTap: () => setDialogState(
                              () => selectedColorHex = hex,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E293B)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
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
                            _membershipTiers[index]['tier'] = nameController
                                .text
                                .trim();
                            _membershipTiers[index]['threshold'] =
                                thresholdController.text.trim();
                            _membershipTiers[index]['discount'] =
                                '${discountController.text.trim()}%';
                            _membershipTiers[index]['icon'] = selectedIcon;
                            _membershipTiers[index]['colorHex'] =
                                selectedColorHex;
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
                    'Khách hàng tích lũy tổng chi tiêu đạt mức tối thiểu dưới đây sẽ được hệ thống phân bậc tương ứng. '
                    'Bấm vào icon bút chì ở mỗi hạng để đổi tên, icon và màu hiển thị.',
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
                          final tierColor = tierColorFromHex(
                            tier['colorHex'],
                          );
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
                                      tierIconFromKey(tier['icon']),
                                      color: tierColor,
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
      errorMaxLines: 2,
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
