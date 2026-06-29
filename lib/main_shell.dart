import 'package:flutter/material.dart';
import 'pages/home/dashboard_page.dart';
import 'pages/ban_hang/sales_page.dart';
import 'pages/don_hang/orders_page.dart';
import 'pages/san_pham/products_page.dart';
import 'pages/dich_vu/services_page.dart';
import 'pages/khach_hang/customers_page.dart';
import 'pages/bao_cao/reports_page.dart';
import 'pages/cai_dat/settings_page.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart'; // Import provider để xử lý sự kiện chuyển theme

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
                            Icon(
                              Icons.storefront_rounded,
                              color: dynamicThemeColor,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            AnimatedOpacity(
                              opacity: isSidebarExpanded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Text(
                                "RJ POS",
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
                      // ĐỔI ICON & SỰ KIỆN TẠI ĐÂY
                      IconButton(
                        onPressed: () {
                          AppThemeProvider().toggleDarkMode();
                        },
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_outlined,
                          color: isDark
                              ? Colors.amber
                              : const Color(0xFF64748B),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: dynamicThemeColor,
                        radius: 16,
                        child: const Text(
                          "RJ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. VÙNG NỘI DUNG TRANG ĐỘNG
                Expanded(
                  child: Container(
                    // Màu nền động thay đổi nhẹ theo chế độ sáng / tối
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
