import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pages/home/dashboard_page.dart';
import 'pages/ban_hang/sales_page.dart';
import 'pages/don_hang/orders_page.dart';
import 'pages/san_pham/danh_muc_sub.dart';
import 'pages/san_pham/product_list_sub.dart';
import 'pages/dich_vu/services_page.dart';
import 'pages/khach_hang/customers_page.dart';
import 'pages/nhan_vien/nhan_vien_page.dart';
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

  // ===== MỚI: TRẠNG THÁI ACCORDION CHO CÁC MENU CÓ MENU CON =====
  // Menu nào đang được bung ra (mặc định RỖNG = tất cả đang ẩn/thu gọn)
  final Set<int> _expandedIndexes = {};
  // Mục con nào đang được chọn bên trong "Sản phẩm" (mặc định là trang Sản phẩm)
  String _selectedProductSubId = 'san_pham';

  final double kExpandedWidth = 240.0;
  final double kCollapsedWidth = 75.0;

  // Lấy tên nhân viên đã đăng nhập thành công từ bộ nhớ AppStorage
  String userName = AppStorage.getString('user_name') ?? 'Quản Trị Viên';

  // ===== DANH SÁCH MENU CHÍNH =====
  // Mục "Sản phẩm" có thêm key 'children' -> Sidebar sẽ tự hiển thị mũi tên
  // xổ/thu gọn cho mục này. Các mục khác không có 'children' hoạt động như cũ.
  final List<Map<String, dynamic>> menuItems = [
    {'title': 'Tổng quan', 'icon': Icons.space_dashboard_rounded},
    {'title': 'Bán hàng', 'icon': Icons.shopping_bag_rounded},
    {'title': 'Đơn hàng', 'icon': Icons.assignment_rounded},
    {
      'title': 'Sản phẩm',
      'icon': Icons.inventory_2_rounded,
      'children': <Map<String, dynamic>>[
        {'id': 'san_pham', 'title': 'Sản phẩm', 'icon': Icons.list_alt_rounded},
        {'id': 'danh_muc', 'title': 'Danh mục', 'icon': Icons.category_rounded},
        {'id': 'kho', 'title': 'Kho', 'icon': Icons.warehouse_rounded},
        {
          'id': 'nha_cung_cap',
          'title': 'Nhà cung cấp',
          'icon': Icons.local_shipping_rounded,
        },
        {
          'id': 'cai_dat_san_pham',
          'title': 'Cài đặt sản phẩm',
          'icon': Icons.settings_suggest_rounded,
        },
      ],
    },
    {'title': 'Dịch vụ', 'icon': Icons.medical_services_rounded},
    {'title': 'Khách hàng', 'icon': Icons.people_rounded},
    {'title': 'Nhân viên', 'icon': Icons.person_rounded},
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
        return _buildProductsContent();
      case 4:
        return const ServicesPage();
      case 5:
        return const CustomersPage();
      case 6:
        return const NhanVienPage();
      case 7:
        return const ReportsPage();
      case 8:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  // ===== MỚI: NỘI DUNG CHO TỪNG MỤC CON CỦA "SẢN PHẨM" =====
  Widget _buildProductsContent() {
    Widget child;
    switch (_selectedProductSubId) {
      case 'san_pham':
        child = const ProductListSubPage();
        break;
      case 'danh_muc':
        child = const DanhMucSubPage();
        break;
      case 'kho':
        child = _buildProductPlaceholder('Kho', Icons.warehouse_rounded);
        break;
      case 'nha_cung_cap':
        child = _buildProductPlaceholder(
          'Nhà cung cấp',
          Icons.local_shipping_rounded,
        );
        break;
      case 'cai_dat_san_pham':
        child = _buildProductPlaceholder(
          'Cài đặt sản phẩm',
          Icons.settings_suggest_rounded,
        );
        break;
      default:
        child = const ProductListSubPage();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  Widget _buildProductPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Giao diện "$title" đang chờ triển khai...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Tiêu đề header: nếu mục đang chọn có menu con thì hiện thêm tên mục con
  String _headerTitle() {
    final item = menuItems[selectedIndex];
    final rawChildren = item['children'];
    if (rawChildren == null) return (item['title'] as String).toUpperCase();

    final children = (rawChildren as List).cast<Map<String, dynamic>>();
    Map<String, dynamic> child = children.first;
    for (final c in children) {
      if (c['id'] == _selectedProductSubId) {
        child = c;
        break;
      }
    }
    return '${item['title']} • ${child['title']}'.toUpperCase();
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
                        _headerTitle(),
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

  // ===== MỤC MENU CHÍNH (hỗ trợ cả loại có menu con và không có) =====
  Widget _buildSidebarItem(int index, Color activeThemeColor, bool isDark) {
    final item = menuItems[index];
    final children = item['children'] as List<Map<String, dynamic>>?;
    final bool isSelected = selectedIndex == index;
    final bool isExpanded = _expandedIndexes.contains(index);
    // Chỉ tô đậm nền cam khi mục KHÔNG có menu con (menu có con chỉ là nhóm,
    // trạng thái "đang xem" thật sự nằm ở mục con bên dưới)
    final bool highlightSolid = isSelected && children == null;

    final parentRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () {
          if (children != null) {
            // Mục có menu con: CHỈ bấm để xổ/thu gọn, không điều hướng
            setState(() {
              if (isExpanded) {
                _expandedIndexes.remove(index);
              } else {
                _expandedIndexes.add(index);
              }
            });
          } else {
            setState(() => selectedIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: highlightSolid ? activeThemeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRect(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kCollapsedWidth - 20,
                  child: Icon(
                    item['icon'],
                    color: highlightSolid
                        ? Colors.white
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                if (isSidebarExpanded)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isSidebarExpanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        item['title'],
                        style: TextStyle(
                          color: highlightSolid
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                          fontWeight: highlightSolid
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                if (children != null && isSidebarExpanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (children == null) return parentRow;

    return Column(
      children: [
        parentRow,
        if (isExpanded && isSidebarExpanded)
          ...children.map(
            (child) => _buildChildItem(index, child, activeThemeColor, isDark),
          ),
      ],
    );
  }

  // ===== MỤC MENU CON (chỉ hiển thị khi menu cha đang được bung ra) =====
  Widget _buildChildItem(
    int parentIndex,
    Map<String, dynamic> child,
    Color activeThemeColor,
    bool isDark,
  ) {
    final bool isChildSelected =
        selectedIndex == parentIndex && _selectedProductSubId == child['id'];

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 4),
      child: InkWell(
        onTap: () => setState(() {
          selectedIndex = parentIndex;
          _selectedProductSubId = child['id'];
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: isChildSelected
                ? activeThemeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                child['icon'],
                size: 16,
                color: isChildSelected
                    ? activeThemeColor
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  child['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isChildSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isChildSelected
                        ? activeThemeColor
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
