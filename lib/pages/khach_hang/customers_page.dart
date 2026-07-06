import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import '/services/app_config.dart';
import '../cai_dat/app_storage.dart';
import '../utils/input_formatters.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
  );

  // ===== HẠNG THÀNH VIÊN MẶC ĐỊNH (khớp với membership_tier_sub.dart) =====
  static const List<Map<String, dynamic>> _defaultMembershipTiers = [
    {
      'id': 'silver',
      'tier': 'Hạng Bạc (Silver)',
      'threshold': '1,000,000',
      'discount': '0%',
    },
    {
      'id': 'gold',
      'tier': 'Hạng Vàng (Gold)',
      'threshold': '3,000,000',
      'discount': '0%',
    },
    {
      'id': 'platinum_new',
      'tier': 'Hạng Bạch Kim (Platinum)',
      'threshold': '10,000,000',
      'discount': '0%',
    },
    {
      'id': 'diamond',
      'tier': 'Hạng Kim Cương (Diamond)',
      'threshold': '50,000,000',
      'discount': '2%',
    },
    {
      'id': 'vip',
      'tier': 'Hạng VIP',
      'threshold': '100,000,000',
      'discount': '5%',
    },
  ];
  List<Map<String, dynamic>> _membershipTiers = List.from(
    _defaultMembershipTiers,
  );

  List<dynamic> _customersList = [];
  bool _isTableLoading = false;
  bool _isSubmitLoading = false;

  // ===== TRẠNG THÁI XUẤT / NHẬP EXCEL =====
  bool _isExporting = false;
  bool _isImporting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;

  // ===== TÌM KIẾM & SẮP XẾP =====
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _sortOption = 'default';

  // ===== PHÂN TRANG =====
  static const int _itemsPerPage = 10;
  int _currentPage = 1;
  static const Map<String, String> _sortLabels = {
    'default': 'Mặc định',
    'chi_tieu_desc': 'Chi tiêu nhiều nhất',
    'chi_tieu_asc': 'Chi tiêu thấp nhất',
    'age_asc': 'Theo tuổi (thấp → cao)',
    'age_desc': 'Theo tuổi (cao → thấp)',
  };

  @override
  void initState() {
    super.initState();
    _loadMembershipTiers();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMembershipTiers() {
    try {
      final cached = AppStorage.getMembershipTiers();
      if (cached != null && cached.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cached);
        _membershipTiers = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _logger.w("Không đọc được cấu hình hạng thành viên, dùng mặc định: $e");
      _membershipTiers = List.from(_defaultMembershipTiers);
    }
  }

  // ===== API CALLS =====
  Future<void> _fetchCustomers() async {
    setState(() {
      _isTableLoading = true;
    });
    try {
      final String currentApiUrl = AppConfig().buildUrl('api/khachhang');
      _logger.i("Đang tải danh sách khách hàng từ: $currentApiUrl");

      final response = await http.get(Uri.parse(currentApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _customersList = data;
        });
      } else {
        _showCustomSnackBar(
          'Không thể tải danh sách khách hàng từ máy chủ',
          Colors.redAccent,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      _logger.e("Lỗi nghiêm trọng khi gọi API lấy dữ liệu: $e");
      _showCustomSnackBar(
        'Lỗi kết nối API: $e',
        Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTableLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addCustomer() async {
    if (_nameController.text.trim().isEmpty) {
      _showCustomSnackBar(
        'Vui lòng nhập tên khách hàng',
        Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      _isSubmitLoading = true;
    });

    String? formattedDate = _selectedDate != null
        ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
        : null;

    Map<String, dynamic> bodyData = {
      "ten": _nameController.text.trim(),
      "sdt": stripNonDigits(_phoneController.text).isEmpty
          ? null
          : stripNonDigits(_phoneController.text),
      "dia_chi": _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      "ngay_sinh": formattedDate,
      "ghi_chu": _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    };

    try {
      final String currentApiUrl = AppConfig().buildUrl('api/khachhang');
      final response = await http.post(
        Uri.parse(currentApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pop();
        _clearForm();
        _showCustomSnackBar(
          'Thêm khách hàng thành công!',
          Theme.of(context).colorScheme.primary,
        );
        _fetchCustomers();
      } else {
        throw Exception('Thất bại khi gửi dữ liệu lên server');
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar(
        'Lỗi kết nối API: $e',
        Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitLoading = false;
        });
      }
    }
  }

  void _showCustomSnackBar(
    String text,
    Color backgroundColor, {
    IconData icon = Icons.check_circle_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _noteController.clear();
    _selectedDate = null;
  }

  // ===== KIỂM TRA TRÙNG SỐ ĐIỆN THOẠI =====
  // Trả về null nếu lỗi kết nối, hoặc Map {exists: bool, id: int?, ten: String?}
  Future<Map<String, dynamic>?> _checkPhoneExists(
    String phoneDigits, {
    int? excludeId,
  }) async {
    try {
      final query = excludeId != null ? '?excludeId=$excludeId' : '';
      final res = await http.get(
        Uri.parse(
          AppConfig().buildUrl('api/khachhang/check-phone/$phoneDigits$query'),
        ),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ===== XÁC THỰC MẬT KHẨU ADMIN (dùng cho Xuất / Nhập Excel) =====
  Future<bool> _verifyAdminPassword(String password) async {
    try {
      final res = await http.post(
        Uri.parse(AppConfig().buildUrl('api/auth/verify-admin-password')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"matKhau": password}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showAdminPasswordDialog({
    required String title,
    required String actionLabel,
    required Future<void> Function() onConfirmed,
  }) async {
    final passController = TextEditingController();
    String? errorText;
    bool isChecking = false;
    bool obscure = true;

    await showDialog(
      context: context,
      barrierDismissible: !isChecking,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDs) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFFEA580C), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thao tác này yêu cầu mật khẩu tài khoản Admin để xác nhận.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passController,
                  obscureText: obscure,
                  autofocus: true,
                  onChanged: (_) => setDs(() => errorText = null),
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu Admin...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    errorText: errorText,
                    prefixIcon: const Icon(
                      Icons.key_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setDs(() => obscure = !obscure),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: errorText != null
                            ? Colors.red
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFEA580C),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isChecking ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: isChecking
                  ? null
                  : () async {
                      final pass = passController.text.trim();
                      if (pass.isEmpty) {
                        setDs(() => errorText = 'Vui lòng nhập mật khẩu');
                        return;
                      }
                      setDs(() => isChecking = true);
                      final ok = await _verifyAdminPassword(pass);
                      if (!ok) {
                        setDs(() {
                          isChecking = false;
                          errorText = 'Mật khẩu Admin không chính xác';
                        });
                        return;
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      await onConfirmed();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HÀM PHỤ CHO XUẤT / NHẬP EXCEL =====
  int _asIntOrZero(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _formatDateForExport(dynamic raw) {
    final s = raw?.toString();
    if (s == null || s.isEmpty || s == 'null') return '';
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  // ===== XUẤT DANH SÁCH KHÁCH HÀNG RA FILE EXCEL =====
  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final workbook = excel_pkg.Excel.createExcel();
      final sheet = workbook['KhachHang'];
      workbook.delete('Sheet1');

      final headers = [
        'ID',
        'Tên khách hàng',
        'Số điện thoại',
        'Địa chỉ',
        'Ngày sinh',
        'Ghi chú',
        'Chi tiêu',
      ];
      sheet.appendRow(headers.map((h) => excel_pkg.TextCellValue(h)).toList());

      // Sắp xếp theo ID từ nhỏ đến lớn trước khi xuất (không ảnh hưởng thứ tự hiển thị trên bảng)
      final sortedForExport = List<dynamic>.from(_customersList)
        ..sort((a, b) => _asIntOrZero(a['id']).compareTo(_asIntOrZero(b['id'])));

      for (final c in sortedForExport) {
        sheet.appendRow([
          excel_pkg.IntCellValue(_asIntOrZero(c['id'])),
          excel_pkg.TextCellValue(c['ten']?.toString() ?? ''),
          excel_pkg.TextCellValue(
            formatPhoneDisplay(c['sdt']) == '-'
                ? ''
                : formatPhoneDisplay(c['sdt']),
          ),
          excel_pkg.TextCellValue(c['dia_chi']?.toString() ?? ''),
          excel_pkg.TextCellValue(_formatDateForExport(c['ngay_sinh'])),
          excel_pkg.TextCellValue(c['ghi_chu']?.toString() ?? ''),
          excel_pkg.DoubleCellValue(_asNum(c['chi_tieu']).toDouble()),
        ]);
      }

      final bytes = workbook.save();
      if (bytes == null) throw Exception('Không tạo được file Excel');

      final fileName = 'khach_hang_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file danh sách khách hàng',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (savePath == null) return; // người dùng bấm Hủy

      final finalPath = savePath.toLowerCase().endsWith('.xlsx')
          ? savePath
          : '$savePath.xlsx';
      await File(finalPath).writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      _showCustomSnackBar(
        'Đã xuất file Excel thành công!',
        Theme.of(context).colorScheme.primary,
      );
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar(
        'Lỗi xuất Excel: $e',
        Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ===== NHẬP DANH SÁCH KHÁCH HÀNG TỪ FILE EXCEL =====
  Future<void> _importFromExcel() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return;

      final bytes = await File(result.files.single.path!).readAsBytes();
      final workbook = excel_pkg.Excel.decodeBytes(bytes);

      if (workbook.tables.isEmpty) {
        throw Exception('File Excel không có sheet dữ liệu nào.');
      }
      final sheet = workbook.tables.values.first;
      if (sheet.maxRows <= 1) {
        throw Exception('File Excel không có dữ liệu (chỉ có dòng tiêu đề).');
      }

      int successCount = 0;
      int updatedCount = 0;
      int failCount = 0;
      final List<String> errors = [];

      // Định dạng cột: 0-ID(để trống nếu thêm mới, điền ID cũ nếu muốn cập nhật),
      // 1-Tên, 2-SĐT, 3-Địa chỉ, 4-Ngày sinh(dd/mm/yyyy), 5-Ghi chú, 6-Chi tiêu(bỏ qua, không cập nhật)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);

        String cellText(int col) {
          if (col >= row.length || row[col] == null) return '';
          return row[col]!.value?.toString().trim() ?? '';
        }

        final idText = cellText(0);
        final ten = cellText(1);
        if (ten.isEmpty) continue; // bỏ qua dòng trống

        // ===== XÁC ĐỊNH TẠO MỚI HAY CẬP NHẬT DỰA VÀO CỘT ID =====
        int? targetId;
        if (idText.isNotEmpty) {
          final parsedId = int.tryParse(idText);
          if (parsedId == null) {
            failCount++;
            errors.add(
              'Dòng ${rowIndex + 1} ("$ten"): Giá trị ID "$idText" không hợp lệ (phải là số hoặc để trống).',
            );
            continue;
          }
          targetId = parsedId;
        }

        final sdt = stripNonDigits(cellText(2));
        if (sdt.isNotEmpty && sdt.length != 10) {
          failCount++;
          errors.add(
            'Dòng ${rowIndex + 1} ("$ten"): Số điện thoại "$sdt" không hợp lệ (phải đủ 10 số hoặc để trống).',
          );
          continue;
        }

        final diaChi = cellText(3);
        final ngaySinhRaw = cellText(4);
        final ghiChu = cellText(5);

        String? formattedDate;
        if (ngaySinhRaw.isNotEmpty) {
          try {
            if (ngaySinhRaw.contains('/')) {
              final parts = ngaySinhRaw.split('/');
              if (parts.length == 3) {
                formattedDate =
                    '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
              }
            } else {
              formattedDate =
                  DateTime.parse(ngaySinhRaw).toIso8601String().split('T').first;
            }
          } catch (_) {
            formattedDate = null;
          }
        }

        try {
          if (targetId != null) {
            // ===== CÓ ID → CẬP NHẬT KHÁCH HÀNG CŨ =====
            final bodyData = {
              "ten": ten,
              "sdt": sdt.isEmpty ? null : sdt,
              "dia_chi": diaChi.isEmpty ? null : diaChi,
              "ngay_sinh": formattedDate,
              "ghi_chu": ghiChu.isEmpty ? null : ghiChu,
            };
            final res = await http.put(
              Uri.parse(AppConfig().buildUrl('api/khachhang/$targetId')),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(bodyData),
            );
            if (res.statusCode == 200) {
              updatedCount++;
            } else if (res.statusCode == 404) {
              failCount++;
              errors.add(
                'Dòng ${rowIndex + 1} ("$ten"): Không tìm thấy khách hàng có ID $targetId để cập nhật.',
              );
            } else {
              failCount++;
              errors.add(
                'Dòng ${rowIndex + 1} ("$ten"): ${jsonDecode(res.body)['message'] ?? 'Lỗi không xác định'}',
              );
            }
          } else {
            // ===== KHÔNG CÓ ID → TẠO MỚI KHÁCH HÀNG =====
            final bodyData = {
              "ten": ten,
              "sdt": sdt.isEmpty ? null : sdt,
              "dia_chi": diaChi.isEmpty ? null : diaChi,
              "ngay_sinh": formattedDate,
              "ghi_chu": ghiChu.isEmpty ? null : ghiChu,
            };
            final res = await http.post(
              Uri.parse(AppConfig().buildUrl('api/khachhang')),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(bodyData),
            );
            if (res.statusCode == 200 || res.statusCode == 201) {
              successCount++;
            } else {
              failCount++;
              errors.add(
                'Dòng ${rowIndex + 1} ("$ten"): ${jsonDecode(res.body)['message'] ?? 'Lỗi không xác định'}',
              );
            }
          }
        } catch (e) {
          failCount++;
          errors.add('Dòng ${rowIndex + 1} ("$ten"): $e');
        }
      }

      await _fetchCustomers();
      if (!mounted) return;

      _showCustomSnackBar(
        'Nhập xong: $successCount thêm mới, $updatedCount cập nhật, $failCount lỗi.',
        failCount > 0 ? Colors.orange : Theme.of(context).colorScheme.primary,
        icon: failCount > 0
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded,
      );

      if (errors.isNotEmpty && mounted) _showImportErrorsDialog(errors);
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar(
        'Lỗi nhập Excel: $e',
        Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Chi tiết lỗi khi nhập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 420,
          height: 300,
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${errors[index]}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C)),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _parseThreshold(dynamic raw) {
    final cleanStr = (raw ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    return cleanStr.isEmpty ? 0 : int.parse(cleanStr);
  }

  Color _tierColor(String id) {
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

  Map<String, dynamic> _resolveTierInfo(num chiTieu) {
    final sortedTiers = List<Map<String, dynamic>>.from(_membershipTiers)
      ..sort(
        (a, b) => _parseThreshold(
          b['threshold'],
        ).compareTo(_parseThreshold(a['threshold'])),
      );

    for (final tier in sortedTiers) {
      final threshold = _parseThreshold(tier['threshold']);
      if (chiTieu >= threshold) {
        return {
          'icon': Icons.stars_rounded,
          'color': _tierColor(tier['id'] ?? ''),
          'label': tier['tier'] ?? '',
        };
      }
    }

    return {
      'icon': Icons.person_outline_rounded,
      'color': const Color(0xFF94A3B8),
      'label': 'Khách hàng mới',
    };
  }

  int? _calcAge(dynamic customer) {
    final raw = customer['ngay_sinh']?.toString();
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    try {
      final dob = DateTime.parse(raw);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  int _compareAge(dynamic a, dynamic b, {required bool ascending}) {
    final ageA = _calcAge(a);
    final ageB = _calcAge(b);
    if (ageA == null && ageB == null) return 0;
    if (ageA == null) return 1;
    if (ageB == null) return -1;
    return ascending ? ageA.compareTo(ageB) : ageB.compareTo(ageA);
  }

  // Danh sách đã lọc theo tìm kiếm + sắp xếp (CHƯA cắt trang)
  List<dynamic> get _filteredSortedList {
    List<dynamic> list = List.from(_customersList);

    if (_searchKeyword.trim().isNotEmpty) {
      final kw = _searchKeyword.trim().toLowerCase();
      list = list.where((c) {
        final ten = (c['ten'] ?? '').toString().toLowerCase();
        final sdt = (c['sdt'] ?? '').toString().toLowerCase();
        final diaChi = (c['dia_chi'] ?? '').toString().toLowerCase();
        return ten.contains(kw) || sdt.contains(kw) || diaChi.contains(kw);
      }).toList();
    }

    switch (_sortOption) {
      case 'chi_tieu_desc':
        list.sort(
          (a, b) => _asNum(b['chi_tieu']).compareTo(_asNum(a['chi_tieu'])),
        );
        break;
      case 'chi_tieu_asc':
        list.sort(
          (a, b) => _asNum(a['chi_tieu']).compareTo(_asNum(b['chi_tieu'])),
        );
        break;
      case 'age_asc':
        list.sort((a, b) => _compareAge(a, b, ascending: true));
        break;
      case 'age_desc':
        list.sort((a, b) => _compareAge(a, b, ascending: false));
        break;
      default:
        break;
    }

    return list;
  }

  // Tổng số trang (luôn tối thiểu 1 trang để tránh chia cho 0)
  int get _totalPages {
    final len = _filteredSortedList.length;
    if (len == 0) return 1;
    return (len / _itemsPerPage).ceil();
  }

  // Trang hiện tại đã được "ghim" trong khoảng hợp lệ [1, totalPages]
  // (phòng trường hợp lọc/tìm kiếm/xóa dữ liệu làm số trang giảm xuống)
  int get _safeCurrentPage => _currentPage.clamp(1, _totalPages);

  // Danh sách khách hàng CHỈ của trang hiện tại (dùng để hiển thị lên bảng)
  List<dynamic> get _paginatedList {
    final list = _filteredSortedList;
    if (list.isEmpty) return [];
    final page = _safeCurrentPage;
    final start = (page - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  void _showEditCustomerDialog(dynamic customer) {
    final nameController = TextEditingController(text: customer['ten'] ?? '');
    final initialPhone = formatPhoneDisplay(customer['sdt']) == '-'
        ? ''
        : formatPhoneDisplay(customer['sdt']);
    final phoneController = TextEditingController(text: initialPhone);
    final addressController = TextEditingController(
      text: customer['dia_chi'] ?? '',
    );
    final noteController = TextEditingController(
      text: customer['ghi_chu'] ?? '',
    );

    DateTime? editSelectedDate;
    final rawDate = customer['ngay_sinh']?.toString();
    if (rawDate != null && rawDate.isNotEmpty && rawDate != 'null') {
      try {
        editSelectedDate = DateTime.parse(rawDate);
      } catch (_) {}
    }

    bool isSubmitting = false;

    // Trạng thái kiểm tra trùng SĐT (loại trừ chính khách hàng đang sửa)
    String? phoneDuplicateError;
    bool isCheckingPhone = false;
    final int currentCustomerId = customer['id'] as int;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Hàm kiểm tra trùng SĐT khi gõ đủ 10 số, bỏ qua chính khách hàng này
            Future<void> handlePhoneChanged(String value) async {
              final digits = stripNonDigits(value);
              setDialogState(() => phoneDuplicateError = null);
              if (digits.length != 10) return;

              setDialogState(() => isCheckingPhone = true);
              final result = await _checkPhoneExists(
                digits,
                excludeId: currentCustomerId,
              );
              if (!dialogContext.mounted) return;

              setDialogState(() {
                isCheckingPhone = false;
                if (result != null && result['exists'] == true) {
                  phoneDuplicateError =
                      'Số điện thoại đã tồn tại (KH: ${result['ten'] ?? 'không rõ tên'})';
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Sửa Thông Tin Khách Hàng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: _dialogInputDecoration(
                          'Tên khách hàng (*)',
                          Icons.person,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneNumberInputFormatter()],
                        onChanged: handlePhoneChanged,
                        decoration:
                            _dialogInputDecoration(
                              'Số điện thoại',
                              Icons.phone,
                            ).copyWith(
                              errorText: phoneDuplicateError,
                              errorMaxLines: 2,
                              suffixIcon: isCheckingPhone
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (phoneDuplicateError != null
                                        ? const Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          )
                                        : null),
                            ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: addressController,
                        decoration: _dialogInputDecoration(
                          'Địa chỉ',
                          Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 15),
                      InkWell(
                        onTap: () async {
                          if (!dialogContext.mounted) return;
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                editSelectedDate ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1930),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => editSelectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _dialogInputDecoration(
                            'Ngày sinh',
                            Icons.cake,
                          ),
                          child: Text(
                            editSelectedDate == null
                                ? 'Chọn ngày sinh'
                                : "${editSelectedDate!.day}/${editSelectedDate!.month}/${editSelectedDate!.year}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: _dialogInputDecoration(
                          'Ghi chú',
                          Icons.note,
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
                      : () {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      (isSubmitting ||
                          isCheckingPhone ||
                          phoneDuplicateError != null)
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            _showCustomSnackBar(
                              'Vui lòng nhập tên khách hàng',
                              Colors.redAccent,
                              icon: Icons.error_outline_rounded,
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          String? formattedDate = editSelectedDate != null
                              ? "${editSelectedDate!.year}-${editSelectedDate!.month.toString().padLeft(2, '0')}-${editSelectedDate!.day.toString().padLeft(2, '0')}"
                              : null;

                          Map<String, dynamic> bodyData = {
                            "ten": nameController.text.trim(),
                            "sdt": stripNonDigits(phoneController.text).isEmpty
                                ? null
                                : stripNonDigits(phoneController.text),
                            "dia_chi": addressController.text.trim().isEmpty
                                ? null
                                : addressController.text.trim(),
                            "ngay_sinh": formattedDate,
                            "ghi_chu": noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          };

                          try {
                            final String currentApiUrl = AppConfig().buildUrl(
                              'api/khachhang/${customer['id']}',
                            );
                            final response = await http.put(
                              Uri.parse(currentApiUrl),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode(bodyData),
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            if (response.statusCode == 200) {
                              Navigator.of(dialogContext).pop();
                              _showCustomSnackBar(
                                'Cập nhật khách hàng thành công!',
                                Theme.of(context).colorScheme.primary,
                              );
                              _fetchCustomers();
                            } else {
                              throw Exception(
                                jsonDecode(response.body)['message'] ??
                                    'Cập nhật thất bại',
                              );
                            }
                          } catch (e) {
                            if (!mounted || !dialogContext.mounted) return;
                            setDialogState(() => isSubmitting = false);
                            _showCustomSnackBar(
                              'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                              Colors.redAccent,
                              icon: Icons.error_outline_rounded,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(dynamic customer) {
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
              const TextSpan(text: 'Xóa khách hàng '),
              TextSpan(
                text: '"${customer['ten'] ?? ''}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Khách hàng sẽ bị xóa khỏi danh sách.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              try {
                final res = await http.delete(
                  Uri.parse(
                    AppConfig().buildUrl('api/khachhang/${customer['id']}'),
                  ),
                );
                if (!mounted) return;
                if (res.statusCode == 200) {
                  _showCustomSnackBar(
                    'Đã xóa khách hàng "${customer['ten']}"',
                    Theme.of(context).colorScheme.primary,
                  );
                  _fetchCustomers();
                } else {
                  throw Exception(jsonDecode(res.body)['message']);
                }
              } catch (e) {
                if (!mounted) return;
                _showCustomSnackBar(
                  'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                  Colors.redAccent,
                  icon: Icons.error_outline_rounded,
                );
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

  void _showViewHistoryDialog(dynamic customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: Color(0xFFEA580C),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lịch sử mua hàng - ${customer['ten'] ?? ''}',
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
                'Tính năng xem lịch sử mua hàng đang được phát triển và sẽ sớm ra mắt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCell(
    String text, {
    required int flex,
    bool isBold = false,
    Color textColor = const Color(0xFF475569),
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: text,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          waitDuration: const Duration(milliseconds: 200),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortOption,
          icon: const Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
          ),
          items: _sortLabels.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _sortOption = v;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
    );
  }

  // Tiện ích để thiết kế Tooltip chung cho Thao tác
  Widget _buildActionButtonTooltip({
    required String message,
    required Widget child,
  }) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      waitDuration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  // ===== KHỐI 3 ICON THAO TÁC (Xem / Sửa / Xóa) =====
  // TÁCH RIÊNG thành hàm dùng chung cho cả dòng dữ liệu, và bọc bằng
  // FittedBox(fit: BoxFit.scaleDown) để nhóm icon TỰ CO LẠI khi khoảng
  // trống bị hẹp đi (ví dụ khi hover mở rộng Sidebar ở main_shell.dart
  // làm bề ngang bảng khách hàng bị thu hẹp đột ngột), thay vì bị TRÀN
  // ra ngoài và hiện dòng cảnh báo overflow màu đỏ/vàng của Flutter.
  Widget _buildActionButtonsRow(dynamic customer) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButtonTooltip(
            message: 'Xem thông tin',
            child: InkWell(
              onTap: () => _showViewHistoryDialog(customer),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildActionButtonTooltip(
            message: 'Sửa thông tin',
            child: InkWell(
              onTap: () => _showEditCustomerDialog(customer),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildActionButtonTooltip(
            message: 'Xóa khách hàng',
            child: InkWell(
              onTap: () => _showDeleteConfirm(customer),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullList = _filteredSortedList;
    final displayedList = _paginatedList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= THANH ĐIỀU KHIỂN CHÍNH =================
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
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {
                        _searchKeyword = v;
                        _currentPage = 1;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm khách hàng...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchKeyword.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: const Color(0xFF94A3B8),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchKeyword = '';
                                    _currentPage = 1;
                                  });
                                },
                              ),
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSortDropdown(),
                  const Spacer(),
                  InkWell(
                    onTap: _fetchCustomers,
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

                  // ===== NÚT XUẤT EXCEL =====
                  OutlinedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _showAdminPasswordDialog(
                              title: 'Xác thực Admin - Xuất Excel',
                              actionLabel: 'Xác nhận & Xuất',
                              onConfirmed: _exportToExcel,
                            ),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _isExporting ? 'Đang xuất...' : 'Xuất Excel',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ===== NÚT NHẬP EXCEL =====
                  OutlinedButton.icon(
                    onPressed: _isImporting
                        ? null
                        : () => _showAdminPasswordDialog(
                              title: 'Xác thực Admin - Nhập Excel',
                              actionLabel: 'Xác nhận & Nhập',
                              onConfirmed: _importFromExcel,
                            ),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.file_upload_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _isImporting ? 'Đang nhập...' : 'Nhập Excel',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  ElevatedButton.icon(
                    onPressed: _showAddCustomerDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Thêm Khách Hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // ================= BẢNG DỮ LIỆU ĐÁP ỨNG (%) =================
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isTableLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEA580C),
                        ),
                      )
                    : fullList.isEmpty
                    ? Center(
                        child: Text(
                          _customersList.isEmpty
                              ? 'Không có dữ liệu hiển thị.'
                              : 'Không tìm thấy khách hàng phù hợp.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : Column(
                        children: [
                          // 1. THANH TIÊU ĐỀ BẢNG (ĐÃ CĂN TRÁI THEO NỘI DUNG)
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
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'ID',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 14,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'Tên KH',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 11,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'SĐT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 21,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'Địa Chỉ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 11,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'Ngày Sinh',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 18,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'Ghi Chú',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Center(
                                      child: const Text(
                                        'Hạng',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 9,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Center(
                                      child: const Text(
                                        'Thao Tác',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 2. DANH SÁCH DÒNG DỮ LIỆU
                          Expanded(
                            child: ListView.builder(
                              itemCount: displayedList.length,
                              itemBuilder: (context, index) {
                                final customer = displayedList[index];

                                String idValue =
                                    customer['id']?.toString() ?? '0';
                                String tenValue =
                                    customer['ten']?.toString() ?? '-';
                                String sdtValue = formatPhoneDisplay(
                                  customer['sdt'],
                                );
                                String diaChiValue =
                                    customer['dia_chi']?.toString() ?? '-';
                                String ghiChuValue =
                                    customer['ghi_chu']?.toString() ?? '-';
                                String rawDate =
                                    customer['ngay_sinh']?.toString() ?? '';
                                String displayDate = '-';
                                if (rawDate.isNotEmpty && rawDate != 'null') {
                                  try {
                                    DateTime parsed = DateTime.parse(rawDate);
                                    displayDate =
                                        "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
                                  } catch (_) {
                                    displayDate = rawDate.length >= 10
                                        ? rawDate.substring(0, 10)
                                        : rawDate;
                                  }
                                }

                                final tierInfo = _resolveTierInfo(
                                  _asNum(customer['chi_tieu']),
                                );

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildResponsiveCell(
                                        idValue,
                                        flex: 5,
                                        textColor: const Color(0xFF64748B),
                                        isBold: true,
                                      ),
                                      _buildResponsiveCell(
                                        tenValue,
                                        flex: 14,
                                        textColor: const Color(0xFF0F172A),
                                        isBold: true,
                                      ),
                                      _buildResponsiveCell(sdtValue, flex: 11),
                                      _buildResponsiveCell(
                                        diaChiValue,
                                        flex: 21,
                                      ),
                                      _buildResponsiveCell(
                                        displayDate,
                                        flex: 11,
                                      ),
                                      _buildResponsiveCell(
                                        ghiChuValue,
                                        flex: 18,
                                      ),

                                      Expanded(
                                        flex: 6,
                                        child: Center(
                                          child: Tooltip(
                                            message: tierInfo['label'],
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1E293B,
                                              ).withValues(alpha: 0.95),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                            waitDuration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Icon(
                                              tierInfo['icon'],
                                              color: tierInfo['color'],
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Ô THAO TÁC — bọc FittedBox để nhóm 3
                                      // icon TỰ CO LẠI khi cột bị hẹp lại
                                      // (ví dụ khi hover mở Sidebar), thay vì
                                      // bị tràn ra ngoài gây dòng cảnh báo đỏ.
                                      Expanded(
                                        flex: 9,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: _buildActionButtonsRow(
                                            customer,
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

            // ================= THANH PHÂN TRANG DƯỚI CÙNG =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fullList.isEmpty
                        ? 'Hiển thị 0/${_customersList.length} khách hàng'
                        : 'Hiển thị ${(_safeCurrentPage - 1) * _itemsPerPage + 1}-${((_safeCurrentPage - 1) * _itemsPerPage + displayedList.length)}/${fullList.length} khách hàng',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (_totalPages > 1)
                    _buildPaginationControls(Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== THANH ĐIỀU KHIỂN PHÂN TRANG (Trước / số trang / Sau) =====
  Widget _buildPaginationControls(Color themeColor) {
    final total = _totalPages;
    final current = _safeCurrentPage;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: current > 1,
          onTap: () => setState(() => _currentPage = current - 1),
        ),
        const SizedBox(width: 6),
        ..._buildPageNumberWidgets(themeColor, total, current),
        const SizedBox(width: 6),
        _buildPageArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: current < total,
          onTap: () => setState(() => _currentPage = current + 1),
        ),
      ],
    );
  }

  Widget _buildPageArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildPageNumberButton(int page, Color themeColor, bool isActive) {
    return InkWell(
      onTap: isActive ? null : () => setState(() => _currentPage = page),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF334155),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPageEllipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
    );
  }

  // Tạo danh sách nút số trang, có rút gọn bằng dấu "..." khi có quá nhiều trang
  List<Widget> _buildPageNumberWidgets(
    Color themeColor,
    int total,
    int current,
  ) {
    final List<Widget> widgets = [];

    if (total <= 7) {
      for (int i = 1; i <= total; i++) {
        widgets.add(_buildPageNumberButton(i, themeColor, i == current));
      }
      return widgets;
    }

    widgets.add(_buildPageNumberButton(1, themeColor, current == 1));

    if (current > 3) widgets.add(_buildPageEllipsis());

    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (int i = start; i <= end; i++) {
      widgets.add(_buildPageNumberButton(i, themeColor, i == current));
    }

    if (current < total - 2) widgets.add(_buildPageEllipsis());

    widgets.add(_buildPageNumberButton(total, themeColor, current == total));

    return widgets;
  }

  void _showAddCustomerDialog() {
    // Trạng thái kiểm tra trùng SĐT, cục bộ cho riêng dialog này
    String? phoneDuplicateError;
    bool isCheckingPhone = false;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Hàm kiểm tra trùng SĐT khi gõ đủ 10 số
            Future<void> handlePhoneChanged(String value) async {
              final digits = stripNonDigits(value);
              setDialogState(() => phoneDuplicateError = null);
              if (digits.length != 10) return;

              setDialogState(() => isCheckingPhone = true);
              final result = await _checkPhoneExists(digits);
              if (!dialogContext.mounted) return;

              setDialogState(() {
                isCheckingPhone = false;
                if (result != null && result['exists'] == true) {
                  phoneDuplicateError =
                      'Số điện thoại đã tồn tại (KH: ${result['ten'] ?? 'không rõ tên'})';
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Thêm Khách Hàng Mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: _dialogInputDecoration(
                          'Tên khách hàng (*)',
                          Icons.person,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneNumberInputFormatter()],
                        onChanged: handlePhoneChanged,
                        decoration:
                            _dialogInputDecoration(
                              'Số điện thoại',
                              Icons.phone,
                            ).copyWith(
                              errorText: phoneDuplicateError,
                              errorMaxLines: 2,
                              suffixIcon: isCheckingPhone
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (phoneDuplicateError != null
                                        ? const Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          )
                                        : null),
                            ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _addressController,
                        decoration: _dialogInputDecoration(
                          'Địa chỉ',
                          Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 15),
                      InkWell(
                        onTap: () async {
                          if (!dialogContext.mounted) return;
                          await _selectDate(dialogContext);
                          setDialogState(() {});
                        },
                        child: InputDecorator(
                          decoration: _dialogInputDecoration(
                            'Ngày sinh',
                            Icons.cake,
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Chọn ngày sinh'
                                : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: _dialogInputDecoration(
                          'Ghi chú',
                          Icons.note,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitLoading
                      ? null
                      : () {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          _clearForm();
                        },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      (_isSubmitLoading ||
                          isCheckingPhone ||
                          phoneDuplicateError != null)
                      ? null
                      : _addCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                  ),
                  child: _isSubmitLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lưu lại',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEA580C)),
      ),
    );
  }
}
