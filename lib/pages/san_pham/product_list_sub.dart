import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/app_config.dart';
import '../utils/input_formatters.dart';

// =====================================================================
// TRANG DANH SÁCH SẢN PHẨM
// =====================================================================
class ProductListSubPage extends StatefulWidget {
  const ProductListSubPage({super.key});

  @override
  State<ProductListSubPage> createState() => _ProductListSubPageState();
}

class _ProductListSubPageState extends State<ProductListSubPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sanPhams = [];
  List<Map<String, dynamic>> _danhMucs = [];
  int _nguongTonKhoThap = 10;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  int? _selectedDanhMucId; // null = tất cả danh mục
  String _sortOption = 'default';

  static const Map<String, String> _sortLabels = {
    'default': 'Mặc định (mới nhất)',
    'ton_kho_asc': 'Tồn kho thấp → cao',
    'gia_asc': 'Giá bán lẻ thấp → cao',
    'gia_desc': 'Giá bán lẻ cao → thấp',
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
    await Future.wait([_fetchSanPham(), _fetchDanhMuc(), _fetchCaiDat()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchSanPham() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/sanpham')),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _sanPhams = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _showSnack('Không thể tải danh sách sản phẩm', isError: true);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối API: $e', isError: true);
    }
  }

  Future<void> _fetchDanhMuc() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/danhmucsanpham')),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _danhMucs = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {
      // Không chặn UI nếu lỗi tải danh mục
    }
  }

  Future<void> _fetchCaiDat() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/caidatsanpham')),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _nguongTonKhoThap = (data['nguongTonKhoThap'] ?? 10) as int;
      }
    } catch (_) {
      // Dùng mặc định 10 nếu lỗi
    }
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

  // ===== TÍNH TOÁN HIỂN THỊ =====
  List<Map<String, dynamic>> _bienTheCua(Map<String, dynamic> sp) {
    return (sp['bienThe'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  int _tongTonKho(Map<String, dynamic> sp) {
    if (sp['quanLyTonKho'] != true) return -1; // -1 = không quản lý
    final list = _bienTheCua(sp);
    int tong = 0;
    for (final bt in list) {
      tong += (bt['tonKho'] as num?)?.toInt() ?? 0;
    }
    return tong;
  }

  String _hienThiGia(Map<String, dynamic> sp) {
    final list = _bienTheCua(sp);
    if (list.isEmpty) return '-';
    final giaList = list
        .map((bt) => (bt['giaBanLe'] as num?)?.toDouble() ?? 0)
        .toList();
    final min = giaList.reduce((a, b) => a < b ? a : b);
    final max = giaList.reduce((a, b) => a > b ? a : b);
    if (min == max) return '${_moneyFormat.format(min)} đ';
    return '${_moneyFormat.format(min)} - ${_moneyFormat.format(max)} đ';
  }

  List<Map<String, dynamic>> get _filteredSorted {
    List<Map<String, dynamic>> list = List.from(_sanPhams);

    if (_selectedDanhMucId != null) {
      list = list.where((s) => s['danhMucId'] == _selectedDanhMucId).toList();
    }

    if (_searchKeyword.trim().isNotEmpty) {
      final kw = _searchKeyword.trim().toLowerCase();
      list = list.where((s) {
        final ten = (s['tenSanPham'] ?? '').toString().toLowerCase();
        final skus = _bienTheCua(
          s,
        ).map((bt) => (bt['maSku'] ?? '').toString().toLowerCase()).join(' ');
        return ten.contains(kw) || skus.contains(kw);
      }).toList();
    }

    switch (_sortOption) {
      case 'ton_kho_asc':
        list.sort((a, b) => _tongTonKho(a).compareTo(_tongTonKho(b)));
        break;
      case 'gia_asc':
        list.sort((a, b) {
          final ga = _bienTheCua(a).isEmpty
              ? 0
              : (_bienTheCua(a).first['giaBanLe'] as num? ?? 0);
          final gb = _bienTheCua(b).isEmpty
              ? 0
              : (_bienTheCua(b).first['giaBanLe'] as num? ?? 0);
          return ga.compareTo(gb);
        });
        break;
      case 'gia_desc':
        list.sort((a, b) {
          final ga = _bienTheCua(a).isEmpty
              ? 0
              : (_bienTheCua(a).first['giaBanLe'] as num? ?? 0);
          final gb = _bienTheCua(b).isEmpty
              ? 0
              : (_bienTheCua(b).first['giaBanLe'] as num? ?? 0);
          return gb.compareTo(ga);
        });
        break;
      default:
        break;
    }

    return list;
  }

  // ===== MỞ DIALOG THÊM / SỬA =====
  void _openFormDialog({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _SanPhamFormDialog(existing: existing, danhMucs: _danhMucs),
    );
    if (result == true) {
      await _fetchSanPham();
      if (mounted) setState(() {});
      _showSnack(
        existing == null ? 'Đã thêm sản phẩm mới!' : 'Đã cập nhật sản phẩm!',
        isError: false,
      );
    }
  }

  void _showDeleteConfirm(Map<String, dynamic> sp) {
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
              const TextSpan(text: 'Xóa sản phẩm '),
              TextSpan(
                text: '"${sp['tenSanPham']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Sản phẩm sẽ được ẩn khỏi danh sách.'),
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
                  Uri.parse(AppConfig().buildUrl('api/sanpham/${sp['id']}')),
                );
                if (res.statusCode == 200) {
                  await _fetchSanPham();
                  if (mounted) setState(() {});
                  _showSnack(
                    'Đã xóa sản phẩm "${sp['tenSanPham']}"',
                    isError: false,
                  );
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
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _sanPhams.isEmpty
                            ? 'Chưa có sản phẩm nào. Bấm "Thêm sản phẩm" để bắt đầu.'
                            : 'Không tìm thấy sản phẩm phù hợp.',
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
        Icon(Icons.inventory_2_rounded, color: themeColor, size: 22),

        const SizedBox(width: 20),
        SizedBox(
          width: 180,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchKeyword = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên/SKU...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
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
        // ===== DROPDOWN DANH MỤC (đã sửa: giới hạn max width + isExpanded + ellipsis) =====
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250, minWidth: 120),
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
                isExpanded:
                    true, // <-- QUAN TRỌNG: ép dropdown co giãn theo Container, không theo text
                hint: const Text(
                  'Tất cả danh mục',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                ),
                icon: const Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'Tất cả danh mục',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ..._danhMucs.map(
                    (d) => DropdownMenuItem<int?>(
                      value: d['id'] as int,
                      child: Text(
                        d['tenDanhMuc'] ?? '',
                        overflow: TextOverflow
                            .ellipsis, // <-- cắt chữ trong menu item khi quá dài
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDanhMucId = v),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
              icon: const Icon(
                Icons.swap_vert_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              items: _sortLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 13),
                      ),
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
            child: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _openFormDialog(),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Thêm sản phẩm',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                SizedBox(width: 46),
                Expanded(flex: 6, child: _HeaderCell('Tên sản phẩm')),
                Expanded(flex: 3, child: _HeaderCell('Danh mục')),
                Expanded(flex: 3, child: _HeaderCell('Giá bán lẻ')),
                Expanded(flex: 3, child: _HeaderCell('Tồn kho', center: true)),
                Expanded(
                  flex: 2,
                  child: _HeaderCell('Trạng thái', center: true),
                ),
                SizedBox(
                  width: 80,
                  child: _HeaderCell('Thao tác', center: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final sp = list[index];
                final tonKho = _tongTonKho(sp);
                final bienTheCount = _bienTheCua(sp).length;
                final tenDanhMuc = sp['danhMucTen'] ?? '- Chưa phân loại -';
                final isThapTon = tonKho >= 0 && tonKho <= _nguongTonKhoThap;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: (sp['hinhAnh'] ?? '').toString().isEmpty
                            ? const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              )
                            : const Icon(
                                Icons.inventory_2_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sp['tenSanPham'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (bienTheCount > 1)
                                Text(
                                  '$bienTheCount biến thể',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            tenDanhMuc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _hienThiGia(sp),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: tonKho < 0
                              ? Text(
                                  'Không quản lý',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isThapTon
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isThapTon)
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 12,
                                          color: Color(0xFFB91C1C),
                                        ),
                                      if (isThapTon) const SizedBox(width: 4),
                                      Text(
                                        '$tonKho',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isThapTon
                                              ? const Color(0xFFB91C1C)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Đang bán',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _openFormDialog(existing: sp),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showDeleteConfirm(sp),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
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
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =====================================================================
// DỮ LIỆU FORM CHO 1 ĐƠN VỊ QUY ĐỔI (bán theo thùng/lốc)
// =====================================================================
class _DonViQuyDoiFormData {
  final int? id;
  final TextEditingController tenDonVi;
  final TextEditingController soLuongQuyDoi;
  final TextEditingController giaBanLe;
  final TextEditingController giaSiLon;
  final TextEditingController giaSiNho;
  final TextEditingController giaCtv;
  final TextEditingController maSkuRieng;

  _DonViQuyDoiFormData({this.id, Map<String, dynamic>? existing})
    : tenDonVi = TextEditingController(text: existing?['tenDonVi'] ?? ''),
      soLuongQuyDoi = TextEditingController(
        text: existing?['soLuongQuyDoi']?.toString() ?? '',
      ),
      giaBanLe = TextEditingController(
        text: existing?['giaBanLe'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaBanLe'])
            : '',
      ),
      giaSiLon = TextEditingController(
        text: existing?['giaSiLon'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaSiLon'])
            : '',
      ),
      giaSiNho = TextEditingController(
        text: existing?['giaSiNho'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaSiNho'])
            : '',
      ),
      giaCtv = TextEditingController(
        text: existing?['giaCtv'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaCtv'])
            : '',
      ),
      maSkuRieng = TextEditingController(text: existing?['maSkuRieng'] ?? '');

  void dispose() {
    tenDonVi.dispose();
    soLuongQuyDoi.dispose();
    giaBanLe.dispose();
    giaSiLon.dispose();
    giaSiNho.dispose();
    giaCtv.dispose();
    maSkuRieng.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      "tenDonVi": tenDonVi.text.trim(),
      "soLuongQuyDoi": int.tryParse(stripNonDigits(soLuongQuyDoi.text)) ?? 0,
      "giaBanLe": _parseMoneyOrNull(giaBanLe.text),
      "giaSiLon": _parseMoneyOrNull(giaSiLon.text),
      "giaSiNho": _parseMoneyOrNull(giaSiNho.text),
      "giaCtv": _parseMoneyOrNull(giaCtv.text),
      "maSkuRieng": maSkuRieng.text.trim().isEmpty
          ? null
          : maSkuRieng.text.trim(),
    };
  }
}

// =====================================================================
// DỮ LIỆU FORM CHO 1 BIẾN THỂ SẢN PHẨM
// =====================================================================
class _BienTheFormData {
  final int? id;
  final TextEditingController tenBienThe;
  final TextEditingController maSku;
  final TextEditingController giaVon;
  final TextEditingController giaBanLe;
  final TextEditingController giaSiLon;
  final TextEditingController giaSiNho;
  final TextEditingController giaCtv;
  final TextEditingController tonKho;
  final List<_DonViQuyDoiFormData> donViQuyDoi;

  _BienTheFormData({this.id, Map<String, dynamic>? existing})
    : tenBienThe = TextEditingController(text: existing?['tenBienThe'] ?? ''),
      maSku = TextEditingController(text: existing?['maSku'] ?? ''),
      giaVon = TextEditingController(
        text: existing?['giaVon'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaVon'])
            : '',
      ),
      giaBanLe = TextEditingController(
        text: existing?['giaBanLe'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaBanLe'])
            : '',
      ),
      giaSiLon = TextEditingController(
        text: existing?['giaSiLon'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaSiLon'])
            : '',
      ),
      giaSiNho = TextEditingController(
        text: existing?['giaSiNho'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaSiNho'])
            : '',
      ),
      giaCtv = TextEditingController(
        text: existing?['giaCtv'] != null
            ? NumberFormat('#,###', 'en_US').format(existing!['giaCtv'])
            : '',
      ),
      tonKho = TextEditingController(
        text: existing?['tonKho']?.toString() ?? '0',
      ),
      donViQuyDoi = ((existing?['donViQuyDoi'] as List?) ?? [])
          .map(
            (d) => _DonViQuyDoiFormData(
              id: d['id'],
              existing: Map<String, dynamic>.from(d),
            ),
          )
          .toList();

  void dispose() {
    tenBienThe.dispose();
    maSku.dispose();
    giaVon.dispose();
    giaBanLe.dispose();
    giaSiLon.dispose();
    giaSiNho.dispose();
    giaCtv.dispose();
    tonKho.dispose();
    for (final d in donViQuyDoi) {
      d.dispose();
    }
  }

  Map<String, dynamic> toJson(bool quanLyTonKho) {
    return {
      if (id != null) "id": id,
      "maSku": maSku.text.trim().isEmpty ? null : maSku.text.trim(),
      "tenBienThe": tenBienThe.text.trim().isEmpty
          ? 'Mặc định'
          : tenBienThe.text.trim(),
      "giaVon": _parseMoney(giaVon.text),
      "giaBanLe": _parseMoney(giaBanLe.text),
      "giaSiLon": _parseMoneyOrNull(giaSiLon.text),
      "giaSiNho": _parseMoneyOrNull(giaSiNho.text),
      "giaCtv": _parseMoneyOrNull(giaCtv.text),
      "tonKho": quanLyTonKho
          ? (int.tryParse(stripNonDigits(tonKho.text)) ?? 0)
          : 0,
      "donViQuyDoi": donViQuyDoi.map((d) => d.toJson()).toList(),
    };
  }
}

double _parseMoney(String text) {
  final clean = stripNonDigits(text);
  return clean.isEmpty ? 0 : double.parse(clean);
}

double? _parseMoneyOrNull(String text) {
  final clean = stripNonDigits(text);
  return clean.isEmpty ? null : double.parse(clean);
}

// =====================================================================
// DIALOG THÊM / SỬA SẢN PHẨM
// =====================================================================
class _SanPhamFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> danhMucs;

  const _SanPhamFormDialog({this.existing, required this.danhMucs});

  @override
  State<_SanPhamFormDialog> createState() => _SanPhamFormDialogState();
}

class _SanPhamFormDialogState extends State<_SanPhamFormDialog> {
  final _tenController = TextEditingController();
  final _moTaController = TextEditingController();
  final _thueSuatController = TextEditingController(text: '10');
  int? _danhMucId;
  bool _coBienThe = false;
  bool _quanLyTonKho = false;
  bool _isSubmitting = false;
  String? _errorText;

  late List<_BienTheFormData> _bienTheList;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _tenController.text = e['tenSanPham'] ?? '';
      _moTaController.text = e['moTa'] ?? '';
      _thueSuatController.text = (e['thueSuat'] ?? 0).toString();
      _danhMucId = e['danhMucId'];
      _coBienThe = e['coBienThe'] == true;
      _quanLyTonKho = e['quanLyTonKho'] != false;
      final list = (e['bienThe'] as List?) ?? [];
      _bienTheList = list
          .map(
            (bt) => _BienTheFormData(
              id: bt['id'],
              existing: Map<String, dynamic>.from(bt),
            ),
          )
          .toList();
      if (_bienTheList.isEmpty) _bienTheList = [_BienTheFormData()];
    } else {
      _bienTheList = [_BienTheFormData()];
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _moTaController.dispose();
    _thueSuatController.dispose();
    for (final bt in _bienTheList) {
      bt.dispose();
    }
    super.dispose();
  }

  void _themBienThe() {
    setState(() => _bienTheList.add(_BienTheFormData()));
  }

  void _xoaBienThe(int index) {
    if (_bienTheList.length <= 1) return;
    setState(() {
      _bienTheList[index].dispose();
      _bienTheList.removeAt(index);
    });
  }

  void _themDonViQuyDoi(int bienTheIndex) {
    setState(
      () => _bienTheList[bienTheIndex].donViQuyDoi.add(_DonViQuyDoiFormData()),
    );
  }

  void _xoaDonViQuyDoi(int bienTheIndex, int dvIndex) {
    setState(() {
      _bienTheList[bienTheIndex].donViQuyDoi[dvIndex].dispose();
      _bienTheList[bienTheIndex].donViQuyDoi.removeAt(dvIndex);
    });
  }

  Future<void> _submit() async {
    final ten = _tenController.text.trim();
    if (ten.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập tên sản phẩm');
      return;
    }
    for (final bt in _bienTheList) {
      if (_parseMoney(bt.giaBanLe.text) <= 0) {
        setState(
          () => _errorText =
              'Vui lòng nhập giá bán lẻ hợp lệ cho tất cả biến thể',
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final body = jsonEncode({
        "tenSanPham": ten,
        "danhMucId": _danhMucId,
        "hinhAnh": widget.existing?['hinhAnh'],
        "moTa": _moTaController.text.trim(),
        "coBienThe": _coBienThe,
        "quanLyTonKho": _quanLyTonKho,
        "thueSuat": double.tryParse(_thueSuatController.text.trim()) ?? 0,
        "bienThe": _bienTheList.map((bt) => bt.toJson(_quanLyTonKho)).toList(),
      });

      final res = _isEditing
          ? await http.put(
              Uri.parse(
                AppConfig().buildUrl('api/sanpham/${widget.existing!['id']}'),
              ),
              headers: {"Content-Type": "application/json"},
              body: body,
            )
          : await http.post(
              Uri.parse(AppConfig().buildUrl('api/sanpham')),
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
        width: 640,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ===== TIÊU ĐỀ =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing
                        ? Icons.edit_note_rounded
                        : Icons.add_box_rounded,
                    color: themeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _isSubmitting ? null : () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== NỘI DUNG FORM (cuộn được) =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _sectionTitle('THÔNG TIN CHUNG'),
                    const SizedBox(height: 12),
                    _label('Tên sản phẩm (*)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tenController,
                      autofocus: true,
                      decoration: _inputDecoration(
                        'VD: Áo thun cổ tròn',
                        themeColor,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _danhMucId,
                                    isExpanded: true,
                                    hint: const Text(
                                      'Chưa phân loại',
                                      style: TextStyle(fontSize: 13),
                                    ),
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
                                    onChanged: (v) =>
                                        setState(() => _danhMucId = v),
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
                              _label('Thuế suất (%)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _thueSuatController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                decoration: _inputDecoration(
                                  'VD: 10',
                                  themeColor,
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
                      decoration: _inputDecoration(
                        'Mô tả ngắn (không bắt buộc)...',
                        themeColor,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ===== 2 SWITCH CẤU HÌNH =====
                    _buildSwitchRow(
                      themeColor: themeColor,
                      icon: Icons.inventory_rounded,
                      title: 'Quản lý tồn kho cho sản phẩm này',
                      subtitle:
                          'Bật để hệ thống theo dõi, trừ/nhập/xuất kho. Tắt nếu không cần theo dõi số lượng.',
                      value: _quanLyTonKho,
                      onChanged: (v) => setState(() => _quanLyTonKho = v),
                    ),
                    const SizedBox(height: 10),
                    _buildSwitchRow(
                      themeColor: themeColor,
                      icon: Icons.style_rounded,
                      title: 'Sản phẩm có nhiều biến thể',
                      subtitle:
                          'Bật nếu sản phẩm có nhiều lựa chọn Size/Màu/Loại... với giá & tồn kho riêng.',
                      value: _coBienThe,
                      onChanged: (v) {
                        setState(() {
                          _coBienThe = v;
                          if (!v && _bienTheList.length > 1) {
                            // Chỉ giữ lại biến thể đầu tiên khi tắt chế độ biến thể
                            for (int i = 1; i < _bienTheList.length; i++) {
                              _bienTheList[i].dispose();
                            }
                            _bienTheList = [_bienTheList.first];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    _sectionTitle(
                      _coBienThe ? 'DANH SÁCH BIẾN THỂ' : 'GIÁ & TỒN KHO',
                    ),
                    const SizedBox(height: 12),
                    ..._bienTheList.asMap().entries.map(
                      (entry) => _buildBienTheBlock(
                        entry.key,
                        entry.value,
                        themeColor,
                      ),
                    ),
                    if (_coBienThe) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _themBienThe,
                        icon: Icon(Icons.add, size: 16, color: themeColor),
                        label: Text(
                          'Thêm biến thể',
                          style: TextStyle(
                            fontSize: 13,
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ===== NÚT HÀNH ĐỘNG =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Lưu thay đổi' : 'Tạo sản phẩm',
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

  Widget _buildBienTheBlock(int index, _BienTheFormData bt, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_coBienThe)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bt.tenBienThe,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _inputDecoration(
                      'Tên biến thể (VD: Size M - Đỏ)',
                      themeColor,
                    ),
                  ),
                ),
                if (_bienTheList.length > 1) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _xoaBienThe(index),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          if (_coBienThe) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniField('Mã SKU', bt.maSku, themeColor)),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMoneyField('Giá vốn', bt.giaVon, themeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMoneyField(
                  'Giá bán lẻ (*)',
                  bt.giaBanLe,
                  themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniMoneyField('Giá sỉ lớn', bt.giaSiLon, themeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMoneyField('Giá sỉ nhỏ', bt.giaSiNho, themeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMoneyField('Giá CTV', bt.giaCtv, themeColor),
              ),
            ],
          ),
          if (_quanLyTonKho) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: _miniField(
                'Tồn kho ban đầu',
                bt.tonKho,
                themeColor,
                isNumberOnly: true,
              ),
            ),
          ],

          // ===== ĐƠN VỊ QUY ĐỔI (bán theo thùng/lốc) =====
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.all_inbox_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              const Text(
                'Đơn vị quy đổi (bán theo thùng/lốc)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _themDonViQuyDoi(index),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: themeColor),
                    const SizedBox(width: 2),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ...bt.donViQuyDoi.asMap().entries.map(
            (dvEntry) => _buildDonViQuyDoiRow(
              index,
              dvEntry.key,
              dvEntry.value,
              themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonViQuyDoiRow(
    int bienTheIndex,
    int dvIndex,
    _DonViQuyDoiFormData dv,
    Color themeColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _miniField(
                  'Tên đơn vị (VD: Thùng)',
                  dv.tenDonVi,
                  themeColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniField(
                  'SL quy đổi (VD: 12)',
                  dv.soLuongQuyDoi,
                  themeColor,
                  isNumberOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _xoaDonViQuyDoi(bienTheIndex, dvIndex),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniMoneyField('Giá bán lẻ', dv.giaBanLe, themeColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniMoneyField('Giá sỉ lớn', dv.giaSiLon, themeColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniMoneyField('Giá sỉ nhỏ', dv.giaSiNho, themeColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniMoneyField('Giá CTV', dv.giaCtv, themeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required Color themeColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: themeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: themeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _miniField(
    String hint,
    TextEditingController controller,
    Color themeColor, {
    bool isNumberOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumberOnly ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumberOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 12.5),
      decoration: _inputDecoration(hint, themeColor, dense: true),
    );
  }

  Widget _miniMoneyField(
    String hint,
    TextEditingController controller,
    Color themeColor,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      style: const TextStyle(fontSize: 12.5),
      decoration: _inputDecoration(hint, themeColor, dense: true),
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

  InputDecoration _inputDecoration(
    String hint,
    Color focusColor, {
    bool dense = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF94A3B8),
        fontSize: dense ? 11.5 : 13,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: dense,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 8 : 10,
      ),
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
