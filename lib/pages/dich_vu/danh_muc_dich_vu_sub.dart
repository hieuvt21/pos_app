import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/app_config.dart';

class DanhMucDichVuSubPage extends StatefulWidget {
  const DanhMucDichVuSubPage({super.key});

  @override
  State<DanhMucDichVuSubPage> createState() => _DanhMucDichVuSubPageState();
}

class _DanhMucDichVuSubPageState extends State<DanhMucDichVuSubPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _danhMucs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _fetchDanhMuc();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== API CALLS =====
  Future<void> _fetchDanhMuc() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/danhmucdicvu')),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _danhMucs = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        _showSnack('Không thể tải danh mục dịch vụ', isError: true);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối API: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchKeyword.trim().isEmpty) return _danhMucs;
    final kw = _searchKeyword.trim().toLowerCase();
    return _danhMucs
        .where(
          (d) => (d['tenDanhMuc'] ?? '').toString().toLowerCase().contains(kw),
        )
        .toList();
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

  // ===== DIALOG: THÊM / SỬA DANH MỤC =====
  void _showFormDialog(Color themeColor, {Map<String, dynamic>? existing}) {
    final isEditing = existing != null;
    final tenController = TextEditingController(
      text: existing?['tenDanhMuc'] ?? '',
    );
    final moTaController = TextEditingController(text: existing?['moTa'] ?? '');
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDs) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.spa_rounded, color: themeColor, size: 22),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Sửa Danh Mục' : 'Thêm Danh Mục Mới',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                _label('Tên danh mục (*)'),
                const SizedBox(height: 6),
                TextField(
                  controller: tenController,
                  autofocus: true,
                  onChanged: (_) => setDs(() => errorText = null),
                  decoration: _inputDecoration(
                    'VD: Chăm sóc da, Massage, Tóc...',
                    themeColor,
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 14),
                _label('Mô tả'),
                const SizedBox(height: 6),
                TextField(
                  controller: moTaController,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    'Mô tả ngắn (không bắt buộc)...',
                    themeColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final ten = tenController.text.trim();
                      if (ten.isEmpty) {
                        setDs(() => errorText = 'Vui lòng nhập tên danh mục');
                        return;
                      }
                      setDs(() => isSubmitting = true);
                      try {
                        final body = jsonEncode({
                          "tenDanhMuc": ten,
                          "moTa": moTaController.text.trim(),
                        });
                        final res = isEditing
                            ? await http.put(
                                Uri.parse(
                                  AppConfig().buildUrl(
                                    'api/danhmucdicvu/${existing['id']}',
                                  ),
                                ),
                                headers: {"Content-Type": "application/json"},
                                body: body,
                              )
                            : await http.post(
                                Uri.parse(
                                  AppConfig().buildUrl('api/danhmucdicvu'),
                                ),
                                headers: {"Content-Type": "application/json"},
                                body: body,
                              );
                        if (res.statusCode == 200) {
                          if (context.mounted) Navigator.pop(context);
                          await _fetchDanhMuc();
                          _showSnack(
                            isEditing
                                ? 'Đã cập nhật danh mục!'
                                : 'Đã tạo danh mục "$ten"!',
                            isError: false,
                          );
                        } else {
                          throw Exception(jsonDecode(res.body)['message']);
                        }
                      } catch (e) {
                        setDs(() {
                          isSubmitting = false;
                          errorText = e.toString().replaceAll('Exception: ', '');
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
                      isEditing ? 'Lưu thay đổi' : 'Tạo danh mục',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOG: XÓA DANH MỤC =====
  void _showDeleteConfirm(Map<String, dynamic> dm) {
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
              const TextSpan(text: 'Xóa danh mục '),
              TextSpan(
                text: '"${dm['tenDanhMuc']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: '? Nếu còn dịch vụ dùng danh mục này, thao tác sẽ thất bại.',
              ),
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
                  Uri.parse(AppConfig().buildUrl('api/danhmucdicvu/${dm['id']}')),
                );
                if (res.statusCode == 200) {
                  await _fetchDanhMuc();
                  _showSnack('Đã xóa danh mục "${dm['tenDanhMuc']}"', isError: false);
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
    final list = _filtered;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.spa_rounded, color: themeColor, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Danh Mục Dịch Vụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchKeyword = v),
                decoration: InputDecoration(
                  hintText: 'Tìm danh mục...',
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
            ElevatedButton.icon(
              onPressed: () => _showFormDialog(themeColor),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'Thêm danh mục',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const Divider(height: 28, color: Color(0xFFF1F5F9)),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.spa_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        _danhMucs.isEmpty
                            ? 'Chưa có danh mục nào. Bấm "Thêm danh mục" để bắt đầu.'
                            : 'Không tìm thấy danh mục phù hợp.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final dm = list[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.spa_rounded, size: 18, color: themeColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dm['tenDanhMuc'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if ((dm['moTa'] ?? '').toString().isNotEmpty)
                                  Text(
                                    dm['moTa'],
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${dm['soLuongDichVu'] ?? 0} dịch vụ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _showFormDialog(themeColor, existing: dm),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showDeleteConfirm(dm),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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

  InputDecoration _inputDecoration(String hint, Color focusColor, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
