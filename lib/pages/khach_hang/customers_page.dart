import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '/services/app_config.dart';
import '../cai_dat/app_storage.dart';

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
  List<Map<String, dynamic>> _membershipTiers = List.from(
    _defaultMembershipTiers,
  );

  List<dynamic> _customersList = [];
  bool _isTableLoading = false;
  bool _isSubmitLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;

  // ===== TÌM KIẾM & SẮP XẾP =====
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _sortOption = 'default';
  static const Map<String, String> _sortLabels = {
    'default': 'Sắp xếp mặc định',
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
        );
      }
    } catch (e) {
      _logger.e("Lỗi nghiêm trọng khi gọi API lấy dữ liệu: $e");
      _showCustomSnackBar('Lỗi kết nối API: $e', Colors.redAccent);
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
      _showCustomSnackBar('Vui lòng nhập tên khách hàng', Colors.redAccent);
      return;
    }

    setState(() {
      _isSubmitLoading = true;
    });

    String? formattedDate = _selectedDate != null
        ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
        : null;

    // Trạng thái mặc định luôn là "1" — do server tự đặt, không cần gửi lên đây.
    Map<String, dynamic> bodyData = {
      "ten": _nameController.text.trim(),
      "sdt": _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
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
          const Color(0xFF10B981),
        );
        _fetchCustomers();
      } else {
        throw Exception('Thất bại khi gửi dữ liệu lên server');
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('Lỗi kết nối API: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitLoading = false;
        });
      }
    }
  }

  void _showCustomSnackBar(String text, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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

  // ===== TIỆN ÍCH: HẠNG THÀNH VIÊN =====
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
      if (chiTieu >= threshold && threshold > 0) {
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

  // ===== TIỆN ÍCH: TUỔI =====
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
    if (ageA == null) return 1; // Khách chưa có ngày sinh luôn đẩy xuống cuối
    if (ageB == null) return -1;
    return ascending ? ageA.compareTo(ageB) : ageB.compareTo(ageA);
  }

  // ===== DANH SÁCH ĐÃ LỌC + SẮP XẾP =====
  List<dynamic> get _displayedList {
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
        break; // Giữ nguyên thứ tự mặc định (server trả về theo id giảm dần)
    }

    return list;
  }

  // ===== SỬA KHÁCH HÀNG =====
  void _showEditCustomerDialog(dynamic customer) {
    final nameController = TextEditingController(text: customer['ten'] ?? '');
    final phoneController = TextEditingController(text: customer['sdt'] ?? '');
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

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                        decoration: _dialogInputDecoration(
                          'Số điện thoại',
                          Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
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
                          final picked = await showDatePicker(
                            context: context,
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            _showCustomSnackBar(
                              'Vui lòng nhập tên khách hàng',
                              Colors.redAccent,
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          String? formattedDate = editSelectedDate != null
                              ? "${editSelectedDate!.year}-${editSelectedDate!.month.toString().padLeft(2, '0')}-${editSelectedDate!.day.toString().padLeft(2, '0')}"
                              : null;

                          Map<String, dynamic> bodyData = {
                            "ten": nameController.text.trim(),
                            "sdt": phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
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

                            if (!mounted) return;

                            if (response.statusCode == 200) {
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              _showCustomSnackBar(
                                'Cập nhật khách hàng thành công!',
                                const Color(0xFF10B981),
                              );
                              _fetchCustomers();
                            } else {
                              throw Exception(
                                jsonDecode(response.body)['message'] ??
                                    'Cập nhật thất bại',
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            if (!dialogContext.mounted) return;
                            setDialogState(() => isSubmitting = false);
                            _showCustomSnackBar(
                              'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                              Colors.redAccent,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
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

  // ===== XÓA (MỀM) KHÁCH HÀNG =====
  void _showDeleteConfirm(dynamic customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await http.delete(
                  Uri.parse(
                    AppConfig().buildUrl('api/khachhang/${customer['id']}'),
                  ),
                );
                if (res.statusCode == 200) {
                  _showCustomSnackBar(
                    'Đã xóa khách hàng "${customer['ten']}"',
                    const Color(0xFF10B981),
                  );
                  _fetchCustomers();
                } else {
                  throw Exception(jsonDecode(res.body)['message']);
                }
              } catch (e) {
                _showCustomSnackBar(
                  'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                  Colors.redAccent,
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

  // ===== XEM LỊCH SỬ MUA HÀNG (GIAO DIỆN TẠM, CHỨC NĂNG LÀM SAU) =====
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
            if (v != null) setState(() => _sortOption = v);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _displayedList;

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
                      onChanged: (v) => setState(() => _searchKeyword = v),
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
                                  setState(() => _searchKeyword = '');
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
                      backgroundColor: const Color(0xFFEA580C),
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
                    : displayedList.isEmpty
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
                          // 1. THANH TIÊU ĐỀ BẢNG
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
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 16,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Họ và Tên',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 11,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Số điện thoại',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 18,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Địa Chỉ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 11,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Ngày Sinh',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 16,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Ghi Chú',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 13,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Hạng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 12,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Thao Tác',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
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
                                String sdtValue =
                                    customer['sdt']?.toString() ?? '-';
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
                                        flex: 16,
                                        textColor: const Color(0xFF0F172A),
                                        isBold: true,
                                      ),
                                      _buildResponsiveCell(sdtValue, flex: 11),
                                      _buildResponsiveCell(
                                        diaChiValue,
                                        flex: 20,
                                      ),
                                      _buildResponsiveCell(
                                        displayDate,
                                        flex: 11,
                                      ),
                                      _buildResponsiveCell(
                                        ghiChuValue,
                                        flex: 16,
                                      ),

                                      // Ô Hạng thành viên
                                      Expanded(
                                        flex: 13,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
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
                                      ),

                                      // Ô Thao tác
                                      Expanded(
                                        flex: 12,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () =>
                                                    _showViewHistoryDialog(
                                                      customer,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.visibility_outlined,
                                                    size: 18,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () =>
                                                    _showEditCustomerDialog(
                                                      customer,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.edit_note_rounded,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _showDeleteConfirm(
                                                  customer,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                    'Hiển thị ${displayedList.length}/${_customersList.length} khách hàng',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isSubmitLoading,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        decoration: _dialogInputDecoration(
                          'Số điện thoại',
                          Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
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
                          await _selectDate(context);
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
                          Navigator.of(context).pop();
                          _clearForm();
                        },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitLoading ? null : _addCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
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
