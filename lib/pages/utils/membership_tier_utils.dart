import 'package:flutter/material.dart';

/// ===== TIỆN ÍCH DÙNG CHUNG CHO HẠNG THÀNH VIÊN =====
/// File này được dùng chung giữa:
///   - lib/pages/cai_dat/cai_dat_cua_hang/membership_tier_sub.dart (trang cấu hình)
///   - lib/pages/khach_hang/customers_page.dart (trang hiển thị icon hạng của khách)
/// để đảm bảo tên / icon / màu của từng hạng luôn đồng bộ ở mọi nơi hiển thị.

/// Danh mục icon có thể chọn cho mỗi hạng thành viên.
/// key: mã icon lưu trong dữ liệu (và trong AppStorage); value: icon + tên hiển thị.
const Map<String, Map<String, dynamic>> tierIconCatalog = {
  'stars_rounded': {'icon': Icons.stars_rounded, 'label': 'Ngôi sao'},
  'workspace_premium_rounded': {
    'icon': Icons.workspace_premium_rounded,
    'label': 'Huy hiệu cao cấp',
  },
  'military_tech_rounded': {
    'icon': Icons.military_tech_rounded,
    'label': 'Huy chương',
  },
  'emoji_events_rounded': {
    'icon': Icons.emoji_events_rounded,
    'label': 'Cúp vinh danh',
  },
  'auto_awesome_rounded': {
    'icon': Icons.auto_awesome_rounded,
    'label': 'Lấp lánh',
  },
  'card_membership_rounded': {
    'icon': Icons.card_membership_rounded,
    'label': 'Thẻ thành viên',
  },
  'shield_rounded': {'icon': Icons.shield_rounded, 'label': 'Khiên bảo vệ'},
  'verified_rounded': {'icon': Icons.verified_rounded, 'label': 'Xác thực'},
  'favorite_rounded': {'icon': Icons.favorite_rounded, 'label': 'Trái tim'},
  'local_fire_department_rounded': {
    'icon': Icons.local_fire_department_rounded,
    'label': 'Ngọn lửa',
  },
  'bolt_rounded': {'icon': Icons.bolt_rounded, 'label': 'Tia sét'},
  'ac_unit_rounded': {'icon': Icons.ac_unit_rounded, 'label': 'Bông tuyết'},
  'yard_rounded': {'icon': Icons.yard_rounded, 'label': 'Sân vườn'},
  'wb_sunny_rounded': {'icon': Icons.wb_sunny_rounded, 'label': 'Mặt trời'},
  'water_drop_rounded': {
    'icon': Icons.water_drop_rounded,
    'label': 'Giọt nước',
  },
  'wallet_giftcard_rounded': {
    'icon': Icons.wallet_giftcard_rounded,
    'label': 'Thẻ quà tặng',
  },
  'volunteer_activism_rounded': {
    'icon': Icons.volunteer_activism_rounded,
    'label': 'Hoạt động tình nguyện',
  },
  'spa_rounded': {'icon': Icons.spa_rounded, 'label': 'Spa'},
  'diamond_rounded': {'icon': Icons.diamond_rounded, 'label': 'Kim cương'},
  'flare_rounded': {'icon': Icons.flare_rounded, 'label': 'Hiệu ứng'},
  'local_florist_rounded': {
    'icon': Icons.local_florist_rounded,
    'label': 'Hoa',
  },
  'filter_vintage_rounded': {
    'icon': Icons.filter_vintage_rounded,
    'label': 'Cổ điển',
  },
};

/// Bảng màu có sẵn để chọn nhanh cho mỗi hạng (mã hex 6 ký tự, KHÔNG có dấu #).
const List<String> tierColorPalette = [
  '94A3B8', // Xám bạc
  'EAB308', // Vàng gold
  '6366F1', // Tím indigo
  '06B6D4', // Xanh ngọc (cyan)
  'EF4444', // Đỏ
  '10B981', // Xanh lá
  'F43F5E', // Hồng rose
  'EA580C', // Cam
  '8B5CF6', // Tím violet
  '0EA5E9', // Xanh dương sky
  '78350F', // Nâu đồng (bronze)
  '1E293B', // Xanh than đen
];

/// Lấy IconData từ mã icon đã lưu; mặc định Icons.stars_rounded nếu không tìm thấy.
IconData tierIconFromKey(String? key) {
  return tierIconCatalog[key]?['icon'] as IconData? ?? Icons.stars_rounded;
}

/// Chuyển mã hex (VD: "94A3B8" hoặc "#94A3B8") thành Color.
Color tierColorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF94A3B8);
  final clean = hex.replaceAll('#', '').trim();
  try {
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return const Color(0xFF94A3B8);
  }
}

/// Chuyển Color thành mã hex 6 ký tự (không có #, viết hoa) để lưu trữ.
String tierColorToHex(Color color) {
  return color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
}

/// Danh sách hạng thành viên MẶC ĐỊNH — dùng làm giá trị khởi tạo khi máy
/// CHƯA có dữ liệu lưu trong AppStorage (key 'membership_tiers_data').
/// Cả trang "Hạng thành viên" (cài đặt) và trang "Khách hàng" đều lấy từ
/// đây làm mặc định ban đầu, sau đó đọc/ghi qua cùng một key AppStorage
/// để luôn đồng bộ với nhau.
List<Map<String, dynamic>> buildDefaultMembershipTiers() => [
  {
    'id': 'silver',
    'tier': 'Hạng Bạc (Silver)',
    'threshold': '5,000,000',
    'discount': '2%',
    'icon': 'stars_rounded',
    'colorHex': '94A3B8',
  },
  {
    'id': 'gold',
    'tier': 'Hạng Vàng (Gold)',
    'threshold': '15,000,000',
    'discount': '5%',
    'icon': 'workspace_premium_rounded',
    'colorHex': 'EAB308',
  },
  {
    'id': 'platinum_new',
    'tier': 'Hạng Bạch Kim (Platinum)',
    'threshold': '30,000,000',
    'discount': '7%',
    'icon': 'military_tech_rounded',
    'colorHex': '6366F1',
  },
  {
    'id': 'diamond',
    'tier': 'Hạng Kim Cương (Diamond)',
    'threshold': '50,000,000',
    'discount': '10%',
    'icon': 'auto_awesome_rounded',
    'colorHex': '06B6D4',
  },
  {
    'id': 'vip',
    'tier': 'Hạng VIP',
    'threshold': '100,000,000',
    'discount': '15%',
    'icon': 'emoji_events_rounded',
    'colorHex': 'EF4444',
  },
];
