import 'package:flutter/material.dart';
import 'cai_dat_chung/app_settings_sub.dart';
import 'cai_dat_cua_hang/membership_tier_sub.dart';
import 'cai_dat_cua_hang/theme.dart';
import 'cai_dat_chung/vai_tro_sub.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSubMenuId = 'app_settings';

  final Map<String, bool> _groupExpansionState = {
    'general': false,
    'system': false,
    'shop':
        true, // Mặc định mở nhóm Cấu hình cửa hàng để người dùng thấy mục Giao diện
  };

  @override
  Widget build(BuildContext context) {
    // Đọc màu chủ đạo động đang kích hoạt từ Theme của hệ thống hệ mặt mặt
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= MENU BÊN TRÁI =================
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NHÓM 1: CÀI ĐẶT CHUNG ---
                    _buildMenuGroupHeader(
                      id: 'general',
                      title: 'CÀI ĐẶT CHUNG',
                      icon: Icons.tune_rounded,
                    ),
                    if (_groupExpansionState['general'] == true) ...[
                      _buildSubMenuItem(
                        id: 'app_settings',
                        title: 'Cấu hình Server',
                        icon: Icons.dns_rounded,
                        activeColor: dynamicThemeColor, // Truyền màu động
                      ),
                      _buildSubMenuItem(
                        id: 'roles',
                        title: 'Vai trò',
                        icon: Icons.admin_panel_settings_rounded,
                        activeColor: dynamicThemeColor,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // --- NHÓM 2: CẤU HÌNH CỬA HÀNG ---
                    _buildMenuGroupHeader(
                      id: 'shop',
                      title: 'CẤU HÌNH CỬA HÀNG',
                      icon: Icons.store_rounded,
                    ),
                    if (_groupExpansionState['shop'] == true) ...[
                      _buildSubMenuItem(
                        id: 'theme_settings',
                        title: 'Giao diện & Chủ đề',
                        icon: Icons.palette_rounded,
                        activeColor: dynamicThemeColor, // Truyền màu động
                      ),
                      _buildSubMenuItem(
                        id: 'membership_tier',
                        title: 'Hạng thành viên',
                        icon: Icons.card_membership_rounded,
                        activeColor: dynamicThemeColor, // Truyền màu động
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),

            // ================= PHẦN HIỂN THỊ NỘI DUNG CHI TIẾT BÊN PHẢI =================
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSubPageContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hàm điều hướng: Trả về widget giao diện tương ứng theo mục đang được chọn
  Widget _buildSubPageContent() {
    switch (_selectedSubMenuId) {
      case 'app_settings':
        return const AppSettingsSubPage();
      case 'theme_settings':
        return const ThemeSubPage(); // Nạp trang chọn màu chủ đề động ta đã viết
      case 'membership_tier':
        return const MembershipTierSubPage();
      case 'roles':
        return const VaiTroSubPage();
      default:
        return const AppSettingsSubPage();
    }
  }

  /// Widget con dựng tiêu đề cho nhóm Menu chính (Hỗ trợ Đóng/Mở dạng Accordion)
  Widget _buildMenuGroupHeader({
    required String id,
    required String title,
    required IconData icon,
  }) {
    bool isExpanded = _groupExpansionState[id] ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          _groupExpansionState[id] = !isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget con dựng từng dòng tùy chọn chi tiết (Sub-menu item) bên trong mỗi nhóm
  Widget _buildSubMenuItem({
    required String id,
    required String title,
    required IconData icon,
    required Color activeColor, // Nhận màu chủ đạo động được truyền xuống
  }) {
    bool isSelected = _selectedSubMenuId == id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubMenuId = id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Nền nút khi được chọn sẽ mờ nhẹ theo tông màu chủ đề hiện tại
            color: isSelected
                ? activeColor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : const Color(0xFF475569),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        activeColor, // Vòng tròn nhỏ báo hiệu đang chọn đổi sang màu động
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
