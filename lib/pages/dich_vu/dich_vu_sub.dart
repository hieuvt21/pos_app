import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/app_config.dart';
import '../utils/input_formatters.dart';

// =====================================================================
// TRANG DANH SÁCH DỊCH VỤ
// =====================================================================
class DichVuSubPage extends StatefulWidget {
  const DichVuSubPage({super.key});

  @override
  State<DichVuSubPage> createState() => _DichVuSubPageState();
}

class _DichVuSubPageState extends State<DichVuSubPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dichVus = [];
  List<Map<String, dynamic>> _danhMucs = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  int? _selectedDanhMucId;
  String _sortOption = 'default';

  static const Map<String, String> _sortLabels = {
    'default': 'Mặc định (mới nhất)',
    'gia_asc': 'Giá thấp → cao',
    'gia_desc': 'Giá cao → thấp',
    'tg_asc': 'Thời lượng thấp → cao',
  };

  final NumberFormat _moneyFormat = NumberFormat('#,###', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== API CALLS =====
  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchDichVu(), _fetchDanhMuc()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchDichVu() async {
    try {
      final res = await http.get(Uri.parse(AppConfig().buildUrl('api/dichvu')));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _dichVus = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _showSnack('Không thể tải danh sách dịch vụ', isError: true);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối API: $e', isError: true);
    }
  }

  Future<void> _fetchDanhMuc() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/danhmucdicvu')),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _danhMucs = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
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

  // ===== LỌC & SẮP XẾP =====
  double _giaNum(Map<String, dynamic> dv) =>
      (dv['gia'] as num?)?.toDouble() ?? 0;

  int _tgNum(Map<String, dynamic> dv) => (dv['thoiLuong'] as num?)?.toInt() ?? 0;

  List<Map<String, dynamic>> get _filteredSorted {
    List<Map<String, dynamic>> list = List.from(_dichVus);

    if (_selectedDanhMucId != null) {
      list = list.where((d) => d['danhMucId'] == _selectedDanhMucId).toList();
    }

    if (_searchKeyword.trim().isNotEmpty) {
      final kw = _searchKeyword.trim().toLowerCase();
      list = list.where((d) {
        final ten = (d['tenDichVu'] ?? '').toString().toLowerCase();
        final moTa = (d['moTa'] ?? '').toString().toLowerCase();
        return ten.contains(kw) || moTa.contains(kw);
      }).toList();
    }

    switch (_sortOption) {
      case 'gia_asc':
        list.sort((a, b) => _giaNum(a).compareTo(_giaNum(b)));
        break;
      case 'gia_desc':
        list.sort((a, b) => _giaNum(b).compareTo(_giaNum(a)));
        break;
      case 'tg_asc':
        list.sort((a, b) => _tgNum(a).compareTo(_tgNum(b)));
        break;
      default:
        break;
    }

    return list;
  }

  // ===== DIALOG THÊM / SỬA =====
  void _openFormDialog({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DichVuFormDialog(
        existing: existing,
        danhMucs: _danhMucs,
      ),
    );
    if (result == true) {
      await _fetchDichVu();
      if (mounted) setState(() {});
      _showSnack(
        existing == null ? 'Đã thêm dịch vụ mới!' : 'Đã cập nhật dịch vụ!',
        isError: false,
      );
    }
  }

  void _showDeleteConfirm(Map<String, dynamic> dv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              const TextSpan(text: 'Xóa dịch vụ '),
              TextSpan(
                text: '"${dv['tenDichVu']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Dịch vụ sẽ được ẩn khỏi danh sách.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await http.delete(
                  Uri.parse(AppConfig().buildUrl('api/dichvu/${dv['id']}')),
                );
                if (res.statusCode == 200) {
                  await _fetchDichVu();
                  if (mounted) setState(() {});
                  _showSnack('Đã xóa dịch vụ "${dv['tenDichVu']}"', isError: false);
                } else {
                  throw Exception(jsonDecode(res.body)['message']);
                }
              } catch (e) {
                _showSnack(
                  'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final list = _filteredSorted;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(themeColor),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        _dichVus.isEmpty
                            ? 'Chưa có dịch vụ nào. Bấm "Thêm dịch vụ" để bắt đầu.'
                            : 'Không tìm thấy dịch vụ phù hợp.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : _buildTable(list, themeColor),
        ),
      ],
    );
  }

  Widget _buildToolbar(Color themeColor) {
    return Row(
      children: [
        Icon(Icons.medical_services_rounded, color: themeColor, size: 22),
        const SizedBox(width: 20),
        // Ô tìm kiếm
        SizedBox(
          width: 180,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchKeyword = v),
            decoration: InputDecoration(
              hintText: 'Tìm dịch vụ...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: themeColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Dropdown danh mục
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, minWidth: 120),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedDanhMucId,
                isExpanded: true,
                hint: const Text(
                  'Tất cả danh mục',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                ),
                icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF94A3B8)),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả danh mục', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  ..._danhMucs.map(
                    (d) => DropdownMenuItem<int?>(
                      value: d['id'] as int,
                      child: Text(d['tenDanhMuc'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDanhMucId = v),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Dropdown sắp xếp
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOption,
              icon: const Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
              items: _sortLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _sortOption = v);
              },
            ),
          ),
        ),
        const Spacer(),
        // Nút refresh
        InkWell(
          onTap: _fetchAll,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _openFormDialog(),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Thêm dịch vụ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> list, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 6, child: _HeaderCell('Tên dịch vụ')),
                Expanded(flex: 3, child: _HeaderCell('Danh mục')),
                Expanded(flex: 3, child: _HeaderCell('Giá')),
                Expanded(flex: 2, child: _HeaderCell('Thời lượng', center: true)),
                Expanded(flex: 2, child: _HeaderCell('Đơn vị')),
                Expanded(flex: 2, child: _HeaderCell('Trạng thái', center: true)),
                SizedBox(width: 80, child: _HeaderCell('Thao tác', center: true)),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final dv = list[index];
                final bool isActive = (dv['trangThai'] ?? '1') == '1';
                final tenDanhMuc = dv['danhMucTen'] ?? '- Chưa phân loại -';
                final gia = (dv['gia'] as num?)?.toDouble() ?? 0;
                final giaUuDai = (dv['giaUuDai'] as num?)?.toDouble();
                final thoiLuong = (dv['thoiLuong'] as num?)?.toInt() ?? 0;
                final donVi = (dv['donVi'] ?? 'Lần').toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      // Tên + mô tả
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.spa_rounded, size: 18, color: themeColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dv['tenDichVu'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((dv['moTa'] ?? '').toString().isNotEmpty)
                                      Text(
                                        dv['moTa'],
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Danh mục
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            tenDanhMuc,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Giá
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_moneyFormat.format(gia)} đ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              if (giaUuDai != null && giaUuDai > 0 && giaUuDai < gia)
                                Text(
                                  '↓ ${_moneyFormat.format(giaUuDai)} đ',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFEA580C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Thời lượng
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: thoiLuong <= 0
                              ? Text(
                                  '-',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$thoiLuong ph',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Đơn vị
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            donVi,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      // Trạng thái
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? 'Đang cung cấp' : 'Tạm ngưng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Thao tác
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _openFormDialog(existing: dv),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showDeleteConfirm(dv),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              ),
                            ),
                          ],
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
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// DIALOG THÊM / SỬA DỊCH VỤ
// =====================================================================
class _DichVuFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> danhMucs;

  const _DichVuFormDialog({this.existing, required this.danhMucs});

  @override
  State<_DichVuFormDialog> createState() => _DichVuFormDialogState();
}

class _DichVuFormDialogState extends State<_DichVuFormDialog> {
  final _tenController = TextEditingController();
  final _moTaController = TextEditingController();
  final _giaController = TextEditingController();
  final _giaUuDaiController = TextEditingController();
  final _thoiLuongController = TextEditingController();
  final _ghiChuController = TextEditingController();

  int? _danhMucId;
  String _donVi = 'Lần';
  String _trangThai = '1';
  bool _isSubmitting = false;
  String? _errorText;

  final List<String> _donViOptions = ['Lần', 'Buổi', 'Tháng', 'Giờ', 'Khóa'];

  bool get _isEditing => widget.existing != null;

  final NumberFormat _moneyFormat = NumberFormat('#,###', 'en_US');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _tenController.text = e['tenDichVu'] ?? '';
      _moTaController.text = e['moTa'] ?? '';
      _danhMucId = e['danhMucId'];
      _donVi = e['donVi'] ?? 'Lần';
      _trangThai = e['trangThai'] ?? '1';
      _ghiChuController.text = e['ghiChu'] ?? '';

      final gia = (e['gia'] as num?)?.toDouble();
      final giaUuDai = (e['giaUuDai'] as num?)?.toDouble();
      final thoiLuong = (e['thoiLuong'] as num?)?.toInt();

      if (gia != null) _giaController.text = _moneyFormat.format(gia);
      if (giaUuDai != null && giaUuDai > 0) {
        _giaUuDaiController.text = _moneyFormat.format(giaUuDai);
      }
      if (thoiLuong != null && thoiLuong > 0) {
        _thoiLuongController.text = thoiLuong.toString();
      }
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _moTaController.dispose();
    _giaController.dispose();
    _giaUuDaiController.dispose();
    _thoiLuongController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  double _parseMoney(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.isEmpty ? 0 : double.parse(clean);
  }

  Future<void> _submit() async {
    final ten = _tenController.text.trim();
    if (ten.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập tên dịch vụ');
      return;
    }
    final gia = _parseMoney(_giaController.text);
    if (gia <= 0) {
      setState(() => _errorText = 'Vui lòng nhập giá dịch vụ hợp lệ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final giaUuDai = _parseMoney(_giaUuDaiController.text);
      final thoiLuong = int.tryParse(_thoiLuongController.text.trim()) ?? 0;

      final body = jsonEncode({
        "tenDichVu": ten,
        "danhMucId": _danhMucId,
        "moTa": _moTaController.text.trim().isEmpty ? null : _moTaController.text.trim(),
        "gia": gia,
        "giaUuDai": giaUuDai > 0 ? giaUuDai : null,
        "thoiLuong": thoiLuong > 0 ? thoiLuong : null,
        "donVi": _donVi,
        "ghiChu": _ghiChuController.text.trim().isEmpty ? null : _ghiChuController.text.trim(),
        "trangThai": _trangThai,
      });

      final res = _isEditing
          ? await http.put(
              Uri.parse(AppConfig().buildUrl('api/dichvu/${widget.existing!['id']}')),
              headers: {"Content-Type": "application/json"},
              body: body,
            )
          : await http.post(
              Uri.parse(AppConfig().buildUrl('api/dichvu')),
              headers: {"Content-Type": "application/json"},
              body: body,
            );

      if (res.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception(jsonDecode(res.body)['message']);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 560,
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            // Tiêu đề
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                    color: themeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Sửa Dịch Vụ' : 'Thêm Dịch Vụ Mới',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _isSubmitting ? null : () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung form (cuộn được)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông báo lỗi
                    if (_errorText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(fontSize: 12.5, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ===== THÔNG TIN CHÍNH =====
                    _sectionTitle('THÔNG TIN CHÍNH'),
                    const SizedBox(height: 12),
                    _label('Tên dịch vụ (*)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tenController,
                      autofocus: true,
                      decoration: _inputDecoration('VD: Chăm sóc da cơ bản, Massage thư giãn...', themeColor),
                    ),
                    const SizedBox(height: 14),

                    // Danh mục + Trạng thái
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Danh mục'),
                              const SizedBox(height: 6),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _danhMucId,
                                    isExpanded: true,
                                    hint: const Text('- Chưa phân loại -', style: TextStyle(fontSize: 13)),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('- Chưa phân loại -'),
                                      ),
                                      ...widget.danhMucs.map(
                                        (d) => DropdownMenuItem<int?>(
                                          value: d['id'] as int,
                                          child: Text(d['tenDanhMuc'] ?? ''),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) => setState(() => _danhMucId = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Trạng thái'),
                              const SizedBox(height: 6),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _trangThai,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: '1', child: Text('Đang cung cấp')),
                                      DropdownMenuItem(value: '0', child: Text('Tạm ngưng')),
                                    ],
                                    onChanged: (v) => setState(() => _trangThai = v ?? '1'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _label('Mô tả'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _moTaController,
                      maxLines: 2,
                      decoration: _inputDecoration('Mô tả ngắn về dịch vụ này...', themeColor),
                    ),
                    const SizedBox(height: 20),

                    // ===== GIÁ & ĐƠN VỊ =====
                    _sectionTitle('GIÁ & ĐƠN VỊ'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Giá dịch vụ (*) (VNĐ)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _giaController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                decoration: _inputDecoration('VD: 250,000', themeColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Giá ưu đãi (VNĐ)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _giaUuDaiController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                decoration: _inputDecoration('Để trống nếu không có', themeColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Thời lượng (phút)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _thoiLuongController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: _inputDecoration('VD: 60', themeColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Đơn vị tính'),
                              const SizedBox(height: 6),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _donVi,
                                    isExpanded: true,
                                    items: _donViOptions
                                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _donVi = v ?? 'Lần'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ===== GHI CHÚ NỘI BỘ =====
                    _sectionTitle('GHI CHÚ NỘI BỘ'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ghiChuController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Ghi chú nội bộ (không hiển thị cho khách)...',
                        themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút hành động
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Lưu thay đổi' : 'Tạo dịch vụ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _sectionTitle(String title) {
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

  InputDecoration _inputDecoration(String hint, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
