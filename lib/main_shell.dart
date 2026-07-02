import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pages/home/dashboard_page.dart';
import 'pages/ban_hang/sales_page.dart';
import 'pages/don_hang/orders_page.dart';
import 'pages/san_pham/products_page.dart';
import 'pages/dich_vu/services_page.dart';
import 'pages/khach_hang/customers_page.dart';
import 'pages/bao_cao/reports_page.dart';
import 'pages/cai_dat/settings_page.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'pages/cai_dat/app_storage.dart';
import 'services/app_config.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool isSidebarExpanded = false;
  int selectedIndex = 0;

  final double kExpandedWidth = 240.0;
  final double kCollapsedWidth = 75.0;

  // Lấy tên nhân viên đã đăng nhập thành công từ bộ nhớ AppStorage
  String userName = AppStorage.getString('user_name') ?? 'Quản Trị Viên';

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'Tổng quan', 'icon': Icons.space_dashboard_rounded},
    {'title': 'Bán hàng', 'icon': Icons.shopping_bag_rounded},
    {'title': 'Đơn hàng', 'icon': Icons.assignment_rounded},
    {'title': 'Sản phẩm', 'icon': Icons.inventory_2_rounded},
    {'title': 'Dịch vụ', 'icon': Icons.medical_services_rounded},
    {'title': 'Khách hàng', 'icon': Icons.people_rounded},
    {'title': 'Báo cáo', 'icon': Icons.analytics_rounded},
    {'title': 'Cài đặt', 'icon': Icons.settings_suggest_rounded},
  ];

  // Hàm helper chuyển đổi chuỗi lưu trong AppStorage thành IconData tương ứng cho Sidebar
  IconData _getWidgetIcon(String iconName) {
    switch (iconName) {
      case 'store_rounded':
        return Icons.store_rounded;
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'coffee_rounded':
        return Icons.coffee_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      case 'spa_rounded':
        return Icons.spa_rounded;
      case 'local_pharmacy_rounded':
        return Icons.local_pharmacy_rounded;
      case 'computer_rounded':
        return Icons.computer_rounded;
      case 'build_rounded':
        return Icons.build_rounded;
      case 'fitness_center_rounded':
        return Icons.fitness_center_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const SalesPage();
      case 2:
        return const OrdersPage();
      case 3:
        return const ProductsPage();
      case 4:
        return const ServicesPage();
      case 5:
        return const CustomersPage();
      case 6:
        return const ReportsPage();
      case 7:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dynamicThemeColor = theme.colorScheme.primary;
    final isDark = AppThemeProvider().isDarkMode;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // ================= SIDEBAR TRẮNG PHẲNG / TỐI PHẲNG =================
          MouseRegion(
            onEnter: (_) => setState(() => isSidebarExpanded = true),
            onExit: (_) => setState(() => isSidebarExpanded = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSidebarExpanded ? kExpandedWidth : kCollapsedWidth,
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  SizedBox(
                    height: 65,
                    child: OverflowBox(
                      maxWidth: kExpandedWidth,
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: [
                            // Sử dụng icon động từ cấu hình cài đặt cửa hàng
                            Icon(
                              _getWidgetIcon(AppStorage.getWidgetIcon()),
                              color: dynamicThemeColor,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            AnimatedOpacity(
                              opacity: isSidebarExpanded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Text(
                                // Sử dụng tiêu đề widget động từ cấu hình cài đặt cửa hàng
                                AppStorage.getWidgetTitle(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: menuItems.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          _buildSidebarItem(index, dynamicThemeColor, isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= PHẦN NỘI DUNG LIỀN MẠCH =================
          Expanded(
            child: Column(
              children: [
                // 1. HEADER CHÍNH
                Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      Text(
                        menuItems[selectedIndex]['title'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),

                      // POPUPMENU BUTTON TÀI KHOẢN
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        elevation: 4,
                        tooltip: '',
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (value) async {
                          if (value == 'profile') {
                            _showEditProfileDialog(context, isDark);
                          } else if (value == 'logout') {
                            await AppStorage.setRawString('jwt_token', '');
                            await AppStorage.setRawString('user_name', '');
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sửa thông tin',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: isDark
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: dynamicThemeColor,
                                radius: 16,
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName
                                            .trim()
                                            .split(' ')
                                            .last
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. VÙNG NỘI DUNG TRANG ĐỘNG
                Expanded(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: _buildPageContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm hiển thị Dialog cập nhật thông tin tài khoản cá nhân
  void _showEditProfileDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController(
      text: AppStorage.getString('user_name') ?? userName,
    );
    final oldPasswordController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool hasNewPassword = passwordController.text.trim().isNotEmpty;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Cập nhật tài khoản',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Họ và tên',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: _dialogInputDecoration(
                      'Nhập họ tên...',
                      Icons.badge_outlined,
                      isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mật khẩu mới (Để trống nếu không đổi)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                    decoration: _dialogInputDecoration(
                      'Nhập mật khẩu mới...',
                      Icons.lock_outline,
                      isDark,
                    ),
                  ),

                  if (hasNewPassword) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Mật khẩu hiện tại (Bắt buộc để đổi mật khẩu)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: oldPasswordController,
                      obscureText: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: _dialogInputDecoration(
                        'Nhập mật khẩu hiện tại...',
                        Icons.lock_person_outlined,
                        isDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: Colors.grey[isDark ? 400 : 600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newName = nameController.text.trim();
                  String newPass = passwordController.text.trim();
                  String? userId = AppStorage.getString('user_id');

                  if (newName.isEmpty || userId == null) return;

                  if (newPass.isNotEmpty &&
                      oldPasswordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập mật khẩu hiện tại để xác nhận đổi mật khẩu!',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  try {
                    final resName = await http.put(
                      Uri.parse(
                        AppConfig().buildUrl('api/auth/update-profile'),
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "id": int.parse(userId),
                        "hoTen": newName,
                      }),
                    );

                    if (resName.statusCode != 200) {
                      throw Exception(
                        jsonDecode(resName.body)['message'] ??
                            'Lỗi cập nhật tên',
                      );
                    }

                    if (newPass.isNotEmpty) {
                      final resPass = await http.put(
                        Uri.parse(
                          AppConfig().buildUrl('api/auth/change-password'),
                        ),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "id": int.parse(userId),
                          "matKhauCu": oldPasswordController.text.trim(),
                          "matKhauMoi": newPass,
                        }),
                      );
                      if (resPass.statusCode != 200) {
                        throw Exception(
                          jsonDecode(resPass.body)['message'] ??
                              'Lỗi đổi mật khẩu',
                        );
                      }
                    }

                    await AppStorage.setRawString('user_name', newName);
                    setState(() => userName = newName);

                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cập nhật thành công!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _dialogInputDecoration(
    String hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey[400],
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFEA580C)),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
      ),
    );
  }

  Widget _buildSidebarItem(int index, Color activeThemeColor, bool isDark) {
    bool isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? activeThemeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRect(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kCollapsedWidth - 20,
                  child: Icon(
                    menuItems[index]['icon'],
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                if (isSidebarExpanded)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isSidebarExpanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        menuItems[index]['title'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
