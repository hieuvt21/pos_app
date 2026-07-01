import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/app_config.dart';

// ===== DATA MODELS =====
class _ActionInfo {
  final String code;
  final String label;
  final IconData icon;
  const _ActionInfo(this.code, this.label, this.icon);
}

class _ModuleInfo {
  final String code;
  final String label;
  final IconData icon;
  final List<_ActionInfo> actions;
  const _ModuleInfo(this.code, this.label, this.icon, this.actions);
}

// ===== CATALOG CỐ ĐỊNH — PHẢI KHỚP VỚI PermissionCatalog BÊN .NET =====
const List<_ModuleInfo> _kCatalog = [
  _ModuleInfo('dashboard', 'Tổng quan', Icons.space_dashboard_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
  ]),
  _ModuleInfo('sales', 'Bán hàng', Icons.shopping_bag_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('create', 'Tạo hóa đơn', Icons.add_circle_outline_rounded),
  ]),
  _ModuleInfo('orders', 'Đơn hàng', Icons.assignment_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('create', 'Thêm mới', Icons.add_circle_outline_rounded),
    _ActionInfo('edit', 'Sửa', Icons.edit_rounded),
    _ActionInfo('delete', 'Xóa', Icons.delete_outline_rounded),
  ]),
  _ModuleInfo('products', 'Sản phẩm', Icons.inventory_2_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('create', 'Thêm mới', Icons.add_circle_outline_rounded),
    _ActionInfo('edit', 'Sửa', Icons.edit_rounded),
    _ActionInfo('delete', 'Xóa', Icons.delete_outline_rounded),
  ]),
  _ModuleInfo('services', 'Dịch vụ', Icons.medical_services_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('create', 'Thêm mới', Icons.add_circle_outline_rounded),
    _ActionInfo('edit', 'Sửa', Icons.edit_rounded),
    _ActionInfo('delete', 'Xóa', Icons.delete_outline_rounded),
  ]),
  _ModuleInfo('customers', 'Khách hàng', Icons.people_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('create', 'Thêm mới', Icons.add_circle_outline_rounded),
    _ActionInfo('edit', 'Sửa', Icons.edit_rounded),
    _ActionInfo('delete', 'Xóa', Icons.delete_outline_rounded),
  ]),
  _ModuleInfo('reports', 'Báo cáo', Icons.analytics_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
    _ActionInfo('export', 'Xuất file', Icons.file_download_outlined),
  ]),
  _ModuleInfo('settings', 'Cài đặt', Icons.settings_suggest_rounded, [
    _ActionInfo('view', 'Xem', Icons.visibility_rounded),
  ]),
];

// ===== WIDGET CHÍNH =====
class VaiTroSubPage extends StatefulWidget {
  const VaiTroSubPage({super.key});

  @override
  State<VaiTroSubPage> createState() => _VaiTroSubPageState();
}

class _VaiTroSubPageState extends State<VaiTroSubPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _roles = [];
  Map<String, dynamic>? _selectedRole;
  Set<String> _editingPermissions = {}; // đang chỉnh sửa, chưa lưu
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  // ===== API CALLS =====
  Future<void> _fetchRoles() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(AppConfig().buildUrl('api/roles')));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final roles = data.map((e) => Map<String, dynamic>.from(e)).toList();
        setState(() {
          _roles = roles;
          // Giữ lại role đang chọn nếu còn tồn tại, ngược lại chọn cái đầu
          if (_selectedRole != null) {
            final found = roles.where((r) => r['id'] == _selectedRole!['id']);
            _selectedRole = found.isNotEmpty
                ? found.first
                : (roles.isNotEmpty ? roles.first : null);
          } else {
            _selectedRole = roles.isNotEmpty ? roles.first : null;
          }
          if (_selectedRole != null) {
            _editingPermissions = Set<String>.from(
              _selectedRole!['modules'] ?? [],
            );
          }
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      _showSnack('Lỗi tải vai trò: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    if (_selectedRole == null || _isSaving) return;

    // Validate: action khác "view" phải có "view" cùng module
    for (final module in _kCatalog) {
      final hasView = _editingPermissions.contains('${module.code}.view');
      final hasOther = module.actions
          .where((a) => a.code != 'view')
          .any((a) => _editingPermissions.contains('${module.code}.${a.code}'));
      if (hasOther && !hasView) {
        _showSnack(
          'Mục "${module.label}": phải bật "Xem" trước khi bật các quyền khác.',
          Colors.orange,
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final res = await http.put(
        Uri.parse(
          AppConfig().buildUrl('api/roles/${_selectedRole!['id']}/quyen'),
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"modules": _editingPermissions.toList()}),
      );
      if (res.statusCode == 200) {
        _showSnack(
          'Đã lưu phân quyền cho vai trò "${_selectedRole!['tenVaiTro']}"!',
          const Color(0xFF10B981),
        );
        _fetchRoles();
      } else {
        throw Exception(jsonDecode(res.body)['message']);
      }
    } catch (e) {
      _showSnack('Lỗi lưu phân quyền: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _selectRole(Map<String, dynamic> role) {
    if (_hasUnsavedChanges) {
      _showUnsavedWarning(() {
        setState(() {
          _selectedRole = role;
          _editingPermissions = Set<String>.from(role['modules'] ?? []);
          _hasUnsavedChanges = false;
        });
      });
      return;
    }
    setState(() {
      _selectedRole = role;
      _editingPermissions = Set<String>.from(role['modules'] ?? []);
      _hasUnsavedChanges = false;
    });
  }

  void _togglePermission(String permCode, bool value) {
    setState(() {
      if (value) {
        _editingPermissions.add(permCode);
        // Auto tick "view" khi tick bất kỳ action nào khác trong cùng module
        final module = permCode.split('.').first;
        _editingPermissions.add('$module.view');
      } else {
        _editingPermissions.remove(permCode);
        // Nếu bỏ "view" thì bỏ luôn tất cả actions khác của module đó
        if (permCode.endsWith('.view')) {
          final module = permCode.split('.').first;
          _editingPermissions.removeWhere((p) => p.startsWith('$module.'));
        }
      }
      _hasUnsavedChanges = true;
    });
  }

  void _toggleAllModule(String moduleCode, bool grantAll) {
    final module = _kCatalog.firstWhere((m) => m.code == moduleCode);
    setState(() {
      if (grantAll) {
        for (final action in module.actions) {
          _editingPermissions.add('$moduleCode.${action.code}');
        }
      } else {
        _editingPermissions.removeWhere((p) => p.startsWith('$moduleCode.'));
      }
      _hasUnsavedChanges = true;
    });
  }

  // ===== DIALOGS =====
  void _showCreateRoleDialog(Color themeColor) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
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
              Icon(Icons.add_moderator_rounded, color: themeColor, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Thêm Vai Trò Mới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  'Tên vai trò (*)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  onChanged: (_) => setDs(() => errorText = null),
                  decoration: _dlgInputDecoration(
                    'VD: Lễ tân, Kế toán...',
                    Icons.badge_outlined,
                    themeColor,
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: _dlgInputDecoration(
                    'Mô tả ngắn về vai trò này...',
                    Icons.notes_rounded,
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setDs(() => errorText = 'Vui lòng nhập tên vai trò');
                        return;
                      }
                      setDs(() => isSubmitting = true);
                      try {
                        final res = await http.post(
                          Uri.parse(AppConfig().buildUrl('api/roles')),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "tenVaiTro": name,
                            "moTa": descController.text.trim(),
                          }),
                        );
                        if (res.statusCode == 200) {
                          if (context.mounted) Navigator.pop(context);
                          _fetchRoles();
                          _showSnack(
                            'Đã tạo vai trò "$name"!',
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
                      'Tạo vai trò',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> role) {
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
              const TextSpan(text: 'Xóa vai trò '),
              TextSpan(
                text: '"${role['tenVaiTro']}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text:
                    '? Nếu có tài khoản đang dùng vai trò này, thao tác sẽ thất bại.',
              ),
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
                  Uri.parse(AppConfig().buildUrl('api/roles/${role['id']}')),
                );
                if (res.statusCode == 200) {
                  if (_selectedRole?['id'] == role['id']) {
                    _selectedRole = null;
                    _editingPermissions.clear();
                  }
                  _fetchRoles();
                  _showSnack(
                    'Đã xóa vai trò "${role['tenVaiTro']}"',
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

  void _showUnsavedWarning(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Chưa lưu thay đổi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có thay đổi chưa được lưu. Chuyển vai trò sẽ mất các thay đổi đó.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Ở lại',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bỏ thay đổi & chuyển'),
          ),
        ],
      ),
    );
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

  // ===== HELPERS =====
  bool get _isAdminRole => _selectedRole?['tenVaiTro'] == 'Admin';

  Color _roleColor(String name) {
    switch (name) {
      case 'Admin':
        return const Color(0xFF8B5CF6);
      case 'Quản lý':
        return const Color(0xFF2563EB);
      case 'Bán hàng':
        return const Color(0xFF10B981);
      case 'Quản lý kho':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _roleIcon(String name) {
    switch (name) {
      case 'Admin':
        return Icons.verified_user_rounded;
      case 'Quản lý':
        return Icons.manage_accounts_rounded;
      case 'Bán hàng':
        return Icons.point_of_sale_rounded;
      case 'Quản lý kho':
        return Icons.warehouse_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  // Kiểm tra toàn bộ actions của module có được tick hết không
  bool _isModuleFullyGranted(String moduleCode) {
    final module = _kCatalog.firstWhere((m) => m.code == moduleCode);
    return module.actions.every(
      (a) => _editingPermissions.contains('$moduleCode.${a.code}'),
    );
  }

  bool _isModulePartiallyGranted(String moduleCode) {
    final module = _kCatalog.firstWhere((m) => m.code == moduleCode);
    final count = module.actions
        .where((a) => _editingPermissions.contains('$moduleCode.${a.code}'))
        .length;
    return count > 0 && count < module.actions.length;
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
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleList(themeColor),
              const SizedBox(width: 20),
              Expanded(child: _buildPermissionPanel(themeColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Row(
      children: [
        Icon(Icons.admin_panel_settings_rounded, color: themeColor, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vai Trò & Phân Quyền',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chọn vai trò bên trái → Tích chọn quyền từng tính năng → Bấm Lưu phân quyền.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showCreateRoleDialog(themeColor),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Thêm vai trò',
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

  Widget _buildRoleList(Color themeColor) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_roles.length} vai trò',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _roles.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final role = _roles[index];
                final selected = role['id'] == _selectedRole?['id'];
                final roleName = role['tenVaiTro'] as String;
                final isAdmin = roleName == 'Admin';
                final color = _roleColor(roleName);
                final permCount = (role['modules'] as List?)?.length ?? 0;

                return InkWell(
                  onTap: () => _selectRole(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? themeColor.withValues(alpha: 0.07)
                          : Colors.transparent,
                      border: selected
                          ? Border(
                              left: BorderSide(color: themeColor, width: 3),
                            )
                          : const Border(
                              left: BorderSide(
                                color: Colors.transparent,
                                width: 3,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _roleIcon(roleName),
                            size: 17,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roleName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: selected
                                      ? themeColor
                                      : const Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAdmin ? 'Toàn quyền' : '$permCount quyền',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isAdmin
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isAdmin)
                          InkWell(
                            onTap: () => _showDeleteConfirm(role),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPanel(Color themeColor) {
    if (_selectedRole == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chọn 1 vai trò để xem và chỉnh sửa phân quyền',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final roleName = _selectedRole!['tenVaiTro'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== TIÊU ĐỀ PANEL =====
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _roleColor(roleName).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _roleIcon(roleName),
                size: 20,
                color: _roleColor(roleName),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (_selectedRole!['moTa'] != null &&
                      _selectedRole!['moTa'].toString().isNotEmpty)
                    Text(
                      _selectedRole!['moTa'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            if (_hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: Colors.orange),
                    SizedBox(width: 5),
                    Text(
                      'Chưa lưu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ===== BANNER ADMIN =====
        if (_isAdminRole)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
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
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vai trò Admin luôn có toàn quyền truy cập mọi tính năng và không thể giới hạn.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6D28D9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ===== DANH SÁCH MODULE =====
        Expanded(
          child: ListView.separated(
            itemCount: _kCatalog.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final module = _kCatalog[index];
              final fullyGranted =
                  _isAdminRole || _isModuleFullyGranted(module.code);
              final partiallyGranted =
                  !_isAdminRole && _isModulePartiallyGranted(module.code);

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: fullyGranted
                        ? themeColor.withValues(alpha: 0.4)
                        : partiallyGranted
                        ? Colors.orange.withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: fullyGranted
                      ? themeColor.withValues(alpha: 0.03)
                      : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của module
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      child: Row(
                        children: [
                          Icon(
                            module.icon,
                            size: 18,
                            color: fullyGranted || partiallyGranted
                                ? themeColor
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              module.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: fullyGranted
                                    ? themeColor
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (!_isAdminRole)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (partiallyGranted)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Text(
                                      'Một phần',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                // Checkbox "cấp tất cả" cho module
                                Transform.scale(
                                  scale: 0.85,
                                  child: Checkbox(
                                    value: fullyGranted
                                        ? true
                                        : (partiallyGranted ? null : false),
                                    tristate: true,
                                    activeColor: themeColor,
                                    onChanged: (v) => _toggleAllModule(
                                      module.code,
                                      !fullyGranted,
                                    ),
                                  ),
                                ),
                                Text(
                                  fullyGranted ? 'Tất cả' : 'Chọn tất',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fullyGranted
                                        ? themeColor
                                        : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    // Action chips
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: module.actions.map((action) {
                          final code = '${module.code}.${action.code}';
                          final checked =
                              _isAdminRole ||
                              _editingPermissions.contains(code);
                          final isView = action.code == 'view';

                          return InkWell(
                            onTap: _isAdminRole
                                ? null
                                : () => _togglePermission(code, !checked),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: checked
                                    ? themeColor
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: checked
                                      ? themeColor
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    checked
                                        ? Icons.check_circle_rounded
                                        : action.icon,
                                    size: 14,
                                    color: checked
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    action.label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: checked
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (isView && checked && !_isAdminRole) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 11,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        if (!_isAdminRole) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_hasUnsavedChanges)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _editingPermissions = Set<String>.from(
                        _selectedRole!['modules'] ?? [],
                      );
                      _hasUnsavedChanges = false;
                    });
                  },
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Hoàn tác'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                )
              else
                const SizedBox(),
              ElevatedButton.icon(
                onPressed: (_hasUnsavedChanges && !_isSaving)
                    ? _savePermissions
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Lưu phân quyền',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

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
