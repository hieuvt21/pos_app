import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/app_config.dart';

class TaiKhoanSubPage extends StatefulWidget {
  const TaiKhoanSubPage({super.key});

  @override
  State<TaiKhoanSubPage> createState() => _TaiKhoanSubPageState();
}

class _TaiKhoanSubPageState extends State<TaiKhoanSubPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _roles = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

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
    await Future.wait([_fetchRoles(), _fetchAccounts()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchRoles() async {
    try {
      final res = await http.get(Uri.parse(AppConfig().buildUrl('api/roles')));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _roles = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {
      // Nếu lỗi tải vai trò, danh sách gán quyền sẽ trống nhưng không chặn tải tài khoản
    }
  }

  Future<void> _fetchAccounts() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/accounts')),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _accounts = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _showSnack('Không thể tải danh sách tài khoản', Colors.redAccent);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối API: $e', Colors.redAccent);
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    if (_searchKeyword.trim().isEmpty) return _accounts;
    final kw = _searchKeyword.trim().toLowerCase();
    return _accounts.where((a) {
      final ten = (a['tenDangNhap'] ?? '').toString().toLowerCase();
      final hoTen = (a['hoTen'] ?? '').toString().toLowerCase();
      return ten.contains(kw) || hoTen.contains(kw);
    }).toList();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ===== DIALOG: THÊM TÀI KHOẢN =====
  void _showCreateDialog(Color themeColor) {
    final userController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    Set<int> selectedRoleIds = {};
    bool isActive = true;
    bool obscure = true;
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
              Icon(Icons.person_add_alt_1_rounded, color: themeColor, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Thêm Tài Khoản Mới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  _dlgLabel('Tên đăng nhập (*)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: userController,
                    autofocus: true,
                    onChanged: (_) => setDs(() => errorText = null),
                    decoration: _dlgInputDecoration(
                      'VD: nhanvien01',
                      Icons.person_outline,
                      themeColor,
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dlgLabel('Mật khẩu (*)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passController,
                    obscureText: obscure,
                    decoration:
                        _dlgInputDecoration(
                          'Tối thiểu 6 ký tự',
                          Icons.lock_outline,
                          themeColor,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setDs(() => obscure = !obscure),
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),
                  _dlgLabel('Họ và tên (*)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: _dlgInputDecoration(
                      'VD: Nguyễn Văn A',
                      Icons.badge_outlined,
                      themeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _dlgLabel('Kích hoạt tài khoản ngay'),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: themeColor,
                        onChanged: (v) => setDs(() => isActive = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dlgLabel('Gán vai trò'),
                  const SizedBox(height: 8),
                  _buildRoleChipPicker(
                    themeColor: themeColor,
                    selectedRoleIds: selectedRoleIds,
                    enabled: true,
                    onChanged: (id, selected) => setDs(() {
                      if (selected) {
                        selectedRoleIds.add(id);
                      } else {
                        selectedRoleIds.remove(id);
                      }
                    }),
                  ),
                ],
              ),
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
                      final username = userController.text.trim();
                      final password = passController.text.trim();
                      final name = nameController.text.trim();

                      if (username.isEmpty || password.isEmpty || name.isEmpty) {
                        setDs(
                          () => errorText = 'Vui lòng điền đầy đủ thông tin bắt buộc',
                        );
                        return;
                      }
                      if (password.length < 6) {
                        setDs(
                          () => errorText = 'Mật khẩu phải có ít nhất 6 ký tự',
                        );
                        return;
                      }

                      setDs(() => isSubmitting = true);
                      try {
                        final res = await http.post(
                          Uri.parse(AppConfig().buildUrl('api/accounts')),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "tenDangNhap": username,
                            "matKhau": password,
                            "hoTen": name,
                            "trangThai": isActive ? "1" : "0",
                            "vaiTroIds": selectedRoleIds.toList(),
                          }),
                        );
                        if (res.statusCode == 200) {
                          if (context.mounted) Navigator.pop(context);
                          await _fetchAccounts();
                          if (mounted) setState(() {});
                          _showSnack(
                            'Đã tạo tài khoản "$username"!',
                            const Color(0xFF10B981),
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
                  : const Text(
                      'Tạo tài khoản',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOG: SỬA TÀI KHOẢN =====
  void _showEditDialog(Map<String, dynamic> account, Color themeColor) {
    final isAdminAccount = account['tenDangNhap'] == 'admin';
    final nameController = TextEditingController(text: account['hoTen']);
    final newPassController = TextEditingController();
    bool isActive = account['trangThai'] == '1';
    Set<int> selectedRoleIds = Set<int>.from(
      (account['vaiTroIds'] as List?)?.map((e) => e as int) ?? [],
    );
    bool obscure = true;
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
              Icon(Icons.manage_accounts_rounded, color: themeColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sửa: ${account['tenDangNhap']}',
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
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdminAccount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: Color(0xFF8B5CF6),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tài khoản admin gốc: không thể khóa hoặc đổi vai trò.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6D28D9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _dlgLabel('Tên đăng nhập'),
                  const SizedBox(height: 6),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(
                      text: account['tenDangNhap'],
                    ),
                    decoration: _dlgInputDecoration(
                      '',
                      Icons.person_outline,
                      themeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dlgLabel('Họ và tên (*)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => setDs(() => errorText = null),
                    decoration: _dlgInputDecoration(
                      'VD: Nguyễn Văn A',
                      Icons.badge_outlined,
                      themeColor,
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dlgLabel('Đặt lại mật khẩu (để trống nếu không đổi)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassController,
                    obscureText: obscure,
                    decoration:
                        _dlgInputDecoration(
                          'Mật khẩu mới...',
                          Icons.lock_reset_rounded,
                          themeColor,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setDs(() => obscure = !obscure),
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _dlgLabel('Trạng thái hoạt động'),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: themeColor,
                        onChanged: isAdminAccount
                            ? null
                            : (v) => setDs(() => isActive = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dlgLabel('Vai trò được gán'),
                  const SizedBox(height: 8),
                  _buildRoleChipPicker(
                    themeColor: themeColor,
                    selectedRoleIds: isAdminAccount
                        ? _roles.map((r) => r['id'] as int).toSet()
                        : selectedRoleIds,
                    enabled: !isAdminAccount,
                    onChanged: (id, selected) => setDs(() {
                      if (selected) {
                        selectedRoleIds.add(id);
                      } else {
                        selectedRoleIds.remove(id);
                      }
                    }),
                  ),
                ],
              ),
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setDs(() => errorText = 'Vui lòng nhập họ tên');
                        return;
                      }
                      final newPass = newPassController.text.trim();
                      if (newPass.isNotEmpty && newPass.length < 6) {
                        setDs(
                          () => errorText =
                              'Mật khẩu mới phải có ít nhất 6 ký tự',
                        );
                        return;
                      }

                      setDs(() => isSubmitting = true);
                      try {
                        final res = await http.put(
                          Uri.parse(
                            AppConfig().buildUrl(
                              'api/accounts/${account['id']}',
                            ),
                          ),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "hoTen": name,
                            "trangThai": isActive ? "1" : "0",
                            "vaiTroIds": selectedRoleIds.toList(),
                            "matKhauMoi": newPass.isEmpty ? null : newPass,
                          }),
                        );
                        if (res.statusCode == 200) {
                          if (context.mounted) Navigator.pop(context);
                          await _fetchAccounts();
                          if (mounted) setState(() {});
                          _showSnack(
                            'Đã cập nhật tài khoản!',
                            const Color(0xFF10B981),
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
                  : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOG: XÓA TÀI KHOẢN =====
  void _showDeleteConfirm(Map<String, dynamic> account) {
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
              const TextSpan(text: 'Xóa tài khoản '),
              TextSpan(
                text: '"${account['tenDangNhap']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Thao tác này không thể hoàn tác.'),
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
                    AppConfig().buildUrl('api/accounts/${account['id']}'),
                  ),
                );
                if (res.statusCode == 200) {
                  await _fetchAccounts();
                  if (mounted) setState(() {});
                  _showSnack(
                    'Đã xóa tài khoản "${account['tenDangNhap']}"',
                    const Color(0xFF10B981),
                  );
                } else {
                  throw Exception(jsonDecode(res.body)['message']);
                }
              } catch (e) {
                _showSnack('Lỗi: $e', Colors.redAccent);
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

  // ===== WIDGET CHỌN VAI TRÒ DẠNG CHIP (dùng chung cho 2 dialog) =====
  Widget _buildRoleChipPicker({
    required Color themeColor,
    required Set<int> selectedRoleIds,
    required bool enabled,
    required void Function(int id, bool selected) onChanged,
  }) {
    if (_roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Chưa có vai trò nào trong hệ thống.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _roles.map((role) {
          final id = role['id'] as int;
          final checked = selectedRoleIds.contains(id);
          return FilterChip(
            label: Text(
              role['tenVaiTro'] ?? '',
              style: const TextStyle(fontSize: 12.5),
            ),
            selected: checked,
            selectedColor: themeColor.withValues(alpha: 0.15),
            checkmarkColor: themeColor,
            labelStyle: TextStyle(
              color: checked ? themeColor : const Color(0xFF64748B),
              fontWeight: checked ? FontWeight.bold : FontWeight.w500,
            ),
            side: BorderSide(
              color: checked ? themeColor : const Color(0xFFE2E8F0),
            ),
            onSelected: enabled
                ? (v) => onChanged(id, v)
                : null,
          );
        }).toList(),
      ),
    );
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(themeColor),
        const Divider(height: 28, color: Color(0xFFF1F5F9)),
        Expanded(child: _buildAccountsTable(themeColor)),
      ],
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Row(
      children: [
        Icon(Icons.people_alt_rounded, color: themeColor, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản Lý Tài Khoản',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tạo, sửa, khóa/mở và gán vai trò cho từng tài khoản đăng nhập hệ thống.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchKeyword = v),
            decoration: InputDecoration(
              hintText: 'Tìm tài khoản...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
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
          onPressed: () => _showCreateDialog(themeColor),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Thêm tài khoản',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsTable(Color themeColor) {
    final list = _filteredAccounts;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Không có tài khoản nào phù hợp',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

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
                Expanded(
                  flex: 3,
                  child: Text(
                    'TÊN ĐĂNG NHẬP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'HỌ TÊN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'VAI TRÒ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TRẠNG THÁI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'THAO TÁC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
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
                final acc = list[index];
                final isActive = acc['trangThai'] == '1';
                final isAdminAccount = acc['tenDangNhap'] == 'admin';
                final roleNames =
                    (acc['vaiTroNames'] as List?)?.cast<String>() ?? [];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAdminAccount
                                    ? Icons.verified_user_rounded
                                    : Icons.person_rounded,
                                size: 15,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                acc['tenDangNhap'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          acc['hoTen'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: roleNames.isEmpty
                            ? const Text(
                                '- Chưa gán -',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: roleNames.map((r) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: themeColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_rounded,
                                size: 12,
                                color: isActive
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFFB91C1C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Hoạt động' : 'Đã khóa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _showEditDialog(acc, themeColor),
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
                            if (!isAdminAccount)
                              InkWell(
                                onTap: () => _showDeleteConfirm(acc),
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

  Widget _dlgLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF475569),
    ),
  );

  InputDecoration _dlgInputDecoration(
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
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
