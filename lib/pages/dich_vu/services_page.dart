import 'package:flutter/material.dart';
import 'danh_muc_dich_vu_sub.dart';
import 'dich_vu_sub.dart';

// =====================================================================
// SHELL TRANG DỊCH VỤ
// Cấu trúc giống ProductsContent trong main_shell.dart:
//   - Danh mục    → DanhMucDichVuSubPage
//   - Dịch vụ     → DichVuSubPage
//   - Combo       → placeholder (chưa triển khai)
//   - Liệu trình  → placeholder (chưa triển khai)
// =====================================================================
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _selectedSubId = 'dich_vu';

  // Danh sách sub-menu bên trái
  static const List<_SubMenuItem> _subMenuItems = [
    _SubMenuItem(
      id: 'danh_muc',
      title: 'Danh mục',
      icon: Icons.spa_rounded,
    ),
    _SubMenuItem(
      id: 'dich_vu',
      title: 'Dịch vụ',
      icon: Icons.medical_services_rounded,
    ),
    _SubMenuItem(
      id: 'combo',
      title: 'Combo',
      icon: Icons.card_giftcard_rounded,
    ),
    _SubMenuItem(
      id: 'lieu_trinh',
      title: 'Liệu trình',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  Widget _buildContent() {
    switch (_selectedSubId) {
      case 'danh_muc':
        return const DanhMucDichVuSubPage();
      case 'dich_vu':
        return const DichVuSubPage();
      case 'combo':
        return _buildPlaceholder('Combo', Icons.card_giftcard_rounded,
            'Gói combo kết hợp nhiều dịch vụ với giá ưu đãi.');
      case 'lieu_trinh':
        return _buildPlaceholder('Liệu trình', Icons.auto_awesome_rounded,
            'Chương trình liệu trình nhiều buổi, theo dõi tiến trình khách hàng.');
      default:
        return const DichVuSubPage();
    }
  }

  Widget _buildPlaceholder(String title, IconData icon, String desc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tính năng "$title" đang được phát triển',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== SIDEBAR SUB-MENU TRÁI =====
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_rounded, size: 16, color: themeColor),
                      const SizedBox(width: 8),
                      Text(
                        'DỊCH VỤ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 6),
                ...List.generate(_subMenuItems.length, (i) {
                  final item = _subMenuItems[i];
                  final isSelected = _selectedSubId == item.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSubId = item.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 17,
                              color: isSelected ? themeColor : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? themeColor : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ===== NỘI DUNG CHI TIẾT =====
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}

// Data class cho sub-menu item
class _SubMenuItem {
  final String id;
  final String title;
  final IconData icon;
  const _SubMenuItem({required this.id, required this.title, required this.icon});
}
