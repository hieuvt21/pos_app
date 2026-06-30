import 'package:flutter/material.dart';
import 'pages/home/dashboard_page.dart';
import 'pages/ban_hang/sales_page.dart';
import 'pages/don_hang/orders_page.dart';
import 'pages/san_pham/products_page.dart';
import 'pages/dich_vu/services_page.dart';
import 'pages/khach_hang/customers_page.dart';
import 'pages/bao_cao/reports_page.dart';
import 'pages/cai_dat/settings_page.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'pages/cai_dat/app_storage.dart'; // Đã import chính xác

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
    {'title': 'Khách hàng', 'icon': Icons.people_alt_rounded},
    {'title': 'Báo cáo', 'icon': Icons.analytics_rounded},
    {'title': 'Cài đặt', 'icon': Icons.settings_rounded},
  ];

  final List<Widget> pages = [
    const DashboardPage(),
    const SalesPage(),
    const OrdersPage(),
    const ProductsPage(),
    const ServicesPage(),
    const CustomersPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  // Hàm hiển thị Dialog cập nhật thông tin tài khoản cá nhân
  void _showEditProfileDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(
      text: AppStorage.getString('user_name') ?? userName,
    );
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cập nhật tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFEA580C),
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Họ và tên nhân viên',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: _dialogInputDecoration(
                  'Nhập họ tên...',
                  Icons.badge_outlined,
                  isDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mật khẩu mới (Để trống nếu không đổi)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: _dialogInputDecoration(
                  'Nhập mật khẩu mới...',
                  Icons.lock_outline,
                  isDark,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await AppStorage.setRawString('user_name', newName);
                setState(() {
                  userName = newName;
                });
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cập nhật họ tên thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ==================== SIDEBAR MENU KHỐI TRÁI ====================
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSidebarExpanded ? kExpandedWidth : kCollapsedWidth,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: isSidebarExpanded
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    children: [
                      if (isSidebarExpanded)
                        const Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFEA580C),
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'RJ CODE POS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.black,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      IconButton(
                        icon: Icon(
                          isSidebarExpanded
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: const Color(0xFFEA580C),
                        ),
                        onPressed: () {
                          setState(() {
                            isSidebarExpanded = !isSidebarExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildMenuItem(index, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),

          // ==================== KHU VỰC NỘI DUNG CHÍNH BÊN PHẢI ====================
          Expanded(
            child: Column(
              children: [
                // Thanh Header trên cùng
                Container(
                  height: 65,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        menuItems[selectedIndex]['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              AppThemeProvider().toggleTheme();
                            },
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 16),

                          // POPUPMENU BUTTON TÀI KHOẢN
                          PopupMenuButton<String>(
                            offset: const Offset(0, 45),
                            elevation: 4,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                _showEditProfileDialog(context);
                              } else if (value == 'logout') {
                                await AppStorage.setRawString('jwt_token', '');
                                await AppStorage.setRawString('user_name', '');
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
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
                                    radius: 16,
                                    backgroundColor: const Color(
                                      0xFFEA580C,
                                    ).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Hiển thị nội dung trang được chọn
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HÀM XÂY DỰNG ITEM SIDEBAR (ĐÃ ĐƯỢC ĐẶT ĐÚNG VỊ TRÍ CLASS THUỘC_STATE)
  Widget _buildMenuItem(int index, bool isDark) {
    bool isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
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
