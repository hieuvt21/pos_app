import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '/services/app_config.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
  );

  List<dynamic> _customersList = [];
  bool _isTableLoading = false;
  bool _isSubmitLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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

    // ĐÃ SỬA: Chuyển các key sang dạng chữ thường đồng bộ với backend .NET mới
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
      "trang_thai": "Hoạt động",
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

  @override
  Widget build(BuildContext context) {
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
                    : _customersList.isEmpty
                    ? Center(
                        child: Text(
                          'Không có dữ liệu hiển thị.',
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
                                  flex: 15,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Tên KH',
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
                                      'SĐT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
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
                                  flex: 12,
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
                                  flex: 20,
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
                                  flex: 10,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Trạng Thái',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 10,
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
                              itemCount: _customersList.length,
                              itemBuilder: (context, index) {
                                final customer = _customersList[index];

                                // ĐÃ SỬA: Map chính xác key chữ viết thường từ backend trả về
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
                                String trangThaiValue =
                                    customer['trang_thai']?.toString() ?? '1';
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
                                        flex: 15,
                                        textColor: const Color(0xFF0F172A),
                                        isBold: true,
                                      ),
                                      _buildResponsiveCell(sdtValue, flex: 12),
                                      _buildResponsiveCell(
                                        diaChiValue,
                                        flex: 20,
                                      ),
                                      _buildResponsiveCell(
                                        displayDate,
                                        flex: 12,
                                      ),
                                      _buildResponsiveCell(
                                        ghiChuValue,
                                        flex: 20,
                                      ),

                                      // Ô Trạng thái
                                      Expanded(
                                        flex: 10,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD1FAE5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                trangThaiValue,
                                                style: const TextStyle(
                                                  color: Color(0xFF065F46),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Ô Thao tác
                                      Expanded(
                                        flex: 10,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_note_rounded,
                                                size: 18,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: Colors.redAccent,
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
                    'Hiển thị dữ liệu',
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
                      : () => Navigator.of(context).pop(),
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
