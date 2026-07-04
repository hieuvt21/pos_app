import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/app_config.dart';
import '/pages/utils/input_formatters.dart';

class NhanVienPage extends StatefulWidget {
  const NhanVienPage({super.key});

  @override
  State<NhanVienPage> createState() => _NhanVienPageState();
}

class _NhanVienPageState extends State<NhanVienPage> {
  bool _isLoading = true;
  List<dynamic> _employees = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  final NumberFormat _moneyFormat = NumberFormat('#,###', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/nhanvien')),
      );
      if (res.statusCode == 200) {
        setState(() => _employees = jsonDecode(res.body));
      } else {
        _showSnack('Không thể tải danh sách nhân viên', isError: true);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối API: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Chỉ hiển thị nhân viên đang hoạt động (trạng thái = "1") + lọc theo từ khóa tìm kiếm
  List<dynamic> get _filteredEmployees {
    final activeOnly = _employees.where((e) => e['trangThai'] == '1').toList();
    if (_searchKeyword.trim().isEmpty) return activeOnly;

    final kw = _searchKeyword.trim().toLowerCase();
    return activeOnly.where((e) {
      final ten = (e['tenNhanVien'] ?? '').toString().toLowerCase();
      final sdt = (e['soDienThoai'] ?? '').toString().toLowerCase();
      final diaChi = (e['diaChi'] ?? '').toString().toLowerCase();
      return ten.contains(kw) || sdt.contains(kw) || diaChi.contains(kw);
    }).toList();
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError
            ? Colors.redAccent
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _formatPhoneDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return digits.isEmpty ? '-' : digits;
    return '${digits.substring(0, 4)}.${digits.substring(4, 7)}.${digits.substring(7)}';
  }

  String _formatDateDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  // ===== FORM DÙNG CHUNG CHO THÊM & SỬA =====
  void _showEmployeeFormDialog(
    Color themeColor, {
    Map<String, dynamic>? existing, // null = thêm mới, có giá trị = sửa
  }) {
    final isEditing = existing != null;

    final nameController = TextEditingController(
      text: existing?['tenNhanVien'] ?? '',
    );
    final phoneController = TextEditingController(
      text: isEditing
          ? _formatPhoneDisplay(existing['soDienThoai']).replaceAll('-', '')
          : '',
    );
    final addressController = TextEditingController(
      text: existing?['diaChi'] ?? '',
    );
    final salaryController = TextEditingController(
      text: isEditing && existing['luongCoBan'] != null
          ? _moneyFormat.format(existing['luongCoBan'])
          : '',
    );
    final noteController = TextEditingController(
      text: existing?['ghiChu'] ?? '',
    );

    DateTime? startDate;
    if (isEditing && existing['ngayBatDau'] != null) {
      try {
        startDate = DateTime.parse(existing['ngayBatDau']);
      } catch (_) {}
    }

    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDs) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.badge_rounded,
                color: themeColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Sửa Thông Tin Nhân Viên' : 'Thêm Nhân Viên Mới',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Tên nhân viên (*)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    onChanged: (_) => setDs(() => errorText = null),
                    decoration: _inputDecoration(
                      'VD: Nguyễn Văn A',
                      Icons.person_outline,
                      themeColor,
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Số điện thoại'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberInputFormatter()],
                    decoration: _inputDecoration(
                      'VD: 0912.345.678',
                      Icons.phone_outlined,
                      themeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Địa chỉ'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    decoration: _inputDecoration(
                      'Nhập địa chỉ...',
                      Icons.location_on_outlined,
                      themeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Ngày bắt đầu làm việc'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2100),
                        locale: const Locale('vi', 'VN'), // <-- VIỆT HÓA LỊCH
                      );
                      if (picked != null) {
                        setDs(() => startDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        '',
                        Icons.event_available_rounded,
                        themeColor,
                      ),
                      child: Text(
                        startDate == null
                            ? 'Chọn ngày bắt đầu'
                            : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                        style: TextStyle(
                          color: startDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Lương cơ bản'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: salaryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: _inputDecoration(
                      'VD: 6,000,000',
                      Icons.payments_outlined,
                      themeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Ghi chú'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      'Ghi chú',
                      Icons.notes_rounded,
                      themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setDs(() => errorText = 'Vui lòng nhập tên nhân viên');
                        return;
                      }

                      setDs(() => isSubmitting = true);

                      final cleanPhone = stripNonDigits(phoneController.text);
                      final cleanSalary = stripNonDigits(salaryController.text);
                      final String? formattedDate = startDate != null
                          ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                          : null;

                      final body = {
                        "tenNhanVien": name,
                        "soDienThoai": cleanPhone.isEmpty ? null : cleanPhone,
                        "diaChi": addressController.text.trim().isEmpty
                            ? null
                            : addressController.text.trim(),
                        "ngayBatDau": formattedDate,
                        "luongCoBan": cleanSalary.isEmpty
                            ? 0
                            : int.parse(cleanSalary),
                        "ghiChu": noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      };

                      try {
                        final res = isEditing
                            ? await http.put(
                                Uri.parse(
                                  AppConfig().buildUrl(
                                    'api/nhanvien/${existing['id']}',
                                  ),
                                ),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode(body),
                              )
                            : await http.post(
                                Uri.parse(AppConfig().buildUrl('api/nhanvien')),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode(body),
                              );

                        if (res.statusCode == 200) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          await _fetchEmployees();
                          _showSnack(
                            isEditing
                                ? 'Đã cập nhật nhân viên!'
                                : 'Đã thêm nhân viên "$name"!',
                            isError: false,
                          );
                        } else {
                          throw Exception(jsonDecode(res.body)['message']);
                        }
                      } catch (e) {
                        setDs(() {
                          isSubmitting = false;
                          errorText = e.toString().replaceAll(
                            'Exception: ',
                            '',
                          );
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Lưu thay đổi' : 'Thêm nhân viên',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOG: XÓA NHÂN VIÊN (xóa mềm) =====
  void _showDeleteConfirm(Map<String, dynamic> nv) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            SizedBox(width: 10),
            Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            children: [
              const TextSpan(text: 'Xóa nhân viên '),
              TextSpan(
                text: '"${nv['tenNhanVien']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Nhân viên sẽ được xóa khỏi danh sách.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final res = await http.delete(
                  Uri.parse(AppConfig().buildUrl('api/nhanvien/${nv['id']}')),
                );
                if (res.statusCode == 200) {
                  await _fetchEmployees();
                  _showSnack(
                    'Đã xóa nhân viên "${nv['tenNhanVien']}"',
                    isError: false,
                  );
                } else {
                  throw Exception(jsonDecode(res.body)['message']);
                }
              } catch (e) {
                _showSnack('Lỗi: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===== DIALOG: XEM BÁO CÁO (placeholder, hoàn thiện sau khi có module Bán hàng) =====
  void _showReportDialog(Map<String, dynamic> nv) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF6366F1),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Báo cáo - ${nv['tenNhanVien']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 40,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Tính năng xem doanh số, hoa hồng và lịch sử bán hàng đang được phát triển và sẽ sớm ra mắt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===== Ô hiển thị có Tooltip (hover xem full nội dung nếu bị cắt) =====
  Widget _cell(
    String text, {
    required int flex,
    bool bold = false,
    Color? color,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: alignment,
          child: Tooltip(
            message: text,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            waitDuration: const Duration(milliseconds: 300),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignment == Alignment.center
                  ? TextAlign.center
                  : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final list = _filteredEmployees;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== THANH ĐIỀU KHIỂN: TÌM KIẾM + THÊM =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, color: themeColor, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Quản Lý Nhân Viên',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchKeyword = v),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, SĐT, địa chỉ...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchKeyword.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: const Color(0xFF94A3B8),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchKeyword = '');
                                },
                              ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _fetchEmployees,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEmployeeFormDialog(themeColor),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      'Thêm nhân viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== BẢNG DỮ LIỆU =====
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? Center(
                        child: Text(
                          _employees.isEmpty
                              ? 'Chưa có nhân viên nào. Bấm "Thêm nhân viên" để bắt đầu.'
                              : 'Không tìm thấy nhân viên phù hợp.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 16,
                                  child: _HeaderCell('Tên nhân viên'),
                                ),
                                Expanded(flex: 12, child: _HeaderCell('SĐT')),
                                Expanded(
                                  flex: 20,
                                  child: _HeaderCell('Địa chỉ'),
                                ),
                                Expanded(
                                  flex: 11,
                                  child: _HeaderCell(
                                    'Ngày bắt đầu',
                                    center: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 13,
                                  child: _HeaderCell(
                                    'Lương cơ bản',
                                    center: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 10,
                                  child: _HeaderCell('Thao tác', center: true),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final nv = Map<String, dynamic>.from(
                                  list[index],
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _cell(
                                        nv['tenNhanVien'] ?? '',
                                        flex: 16,
                                        bold: true,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      _cell(
                                        _formatPhoneDisplay(nv['soDienThoai']),
                                        flex: 12,
                                      ),
                                      _cell(
                                        (nv['diaChi'] ?? '').toString().isEmpty
                                            ? '-'
                                            : nv['diaChi'],
                                        flex: 20,
                                      ),
                                      _cell(
                                        _formatDateDisplay(nv['ngayBatDau']),
                                        flex: 11,
                                        alignment: Alignment.center,
                                      ),
                                      _cell(
                                        '${_moneyFormat.format(nv['luongCoBan'] ?? 0)} đ',
                                        flex: 13,
                                        bold: true,
                                        color: const Color(0xFF10B981),
                                        alignment: Alignment.center,
                                      ),
                                      Expanded(
                                        flex: 10,
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _actionIcon(
                                                  tooltip:
                                                      'Xem báo cáo / doanh số',
                                                  icon: Icons.bar_chart_rounded,
                                                  color: const Color(
                                                    0xFF6366F1,
                                                  ),
                                                  onTap: () =>
                                                      _showReportDialog(nv),
                                                ),
                                                _actionIcon(
                                                  tooltip: 'Sửa thông tin',
                                                  icon: Icons.edit_note_rounded,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                  onTap: () =>
                                                      _showEmployeeFormDialog(
                                                        themeColor,
                                                        existing: nv,
                                                      ),
                                                ),
                                                _actionIcon(
                                                  tooltip: 'Xóa nhân viên',
                                                  icon: Icons
                                                      .delete_outline_rounded,
                                                  color: Colors.redAccent,
                                                  onTap: () =>
                                                      _showDeleteConfirm(nv),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF475569),
    ),
  );

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color focusColor, {
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );

    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: child,
      ),
    );
  }
}
