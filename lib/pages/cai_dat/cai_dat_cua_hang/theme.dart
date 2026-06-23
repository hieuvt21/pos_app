import 'package:flutter/material.dart';
import 'theme_provider.dart'; // Đảm bảo import cùng cấp thư mục chuẩn xác

class ThemeSubPage extends StatefulWidget {
  const ThemeSubPage({super.key});

  @override
  State<ThemeSubPage> createState() => _ThemeSubPageState();
}

class _ThemeSubPageState extends State<ThemeSubPage> {
  // Tạo bản sao trạng thái tạm thời để xử lý khi bấm hủy/lưu
  late AppThemeMode _tempSelectedTheme;

  @override
  void initState() {
    super.initState();
    // Lấy chủ đề hiện tại đang áp dụng của hệ thống làm mặc định ban đầu
    _tempSelectedTheme = AppThemeProvider().currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Theme.of(context) để trang này lập tức đổi màu theo thời gian thực khi nhấn Áp dụng
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= HEADER TIÊU ĐỀ =================
        Row(
          children: [
            Icon(
              Icons.palette_rounded,
              color: dynamicThemeColor, // Đổi màu icon động theo hệ thống
              size: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Cấu hình Giao diện & Chủ đề',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Lựa chọn màu sắc chủ đạo cho hệ thống giao diện POS. Màu sắc được chọn sẽ áp dụng đồng bộ lên toàn bộ thanh điều hướng, nút bấm, và các thành phần trạng thái khác.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const Divider(height: 32, color: Color(0xFFF1F5F9)),

        // ================= DANH SÁCH CÁC MÀU CHỦ ĐỀ =================
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Hiển thị 3 cột
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: AppThemeMode.values.length,
            itemBuilder: (context, index) {
              final themeMode = AppThemeMode.values[index];
              final isSelected = _tempSelectedTheme == themeMode;

              return InkWell(
                onTap: () {
                  setState(() {
                    _tempSelectedTheme =
                        themeMode; // Chọn tạm thời, chưa lưu vào máy
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? themeMode.color
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeMode.color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Vòng tròn màu sắc minh họa
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeMode.color,
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Tên hiển thị chủ đề
                      Expanded(
                        child: Text(
                          themeMode.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? themeMode.color
                                : const Color(0xFF334155),
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

        const Divider(height: 24, color: Color(0xFFF1F5F9)),

        // ================= THANH NÚT ĐIỀU HƯỚNG DƯỚI ĐÁY =================
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Khôi phục lại màu cũ đang chạy trong hệ thống, hủy chọn tạm thời
                  _tempSelectedTheme = AppThemeProvider().currentTheme;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hủy thay đổi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // Áp dụng lưu cấu hình màu sắc mới lên hệ thống trung tâm
                AppThemeProvider().changeTheme(_tempSelectedTheme);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Đã cập nhật giao diện chủ đề mới thành công!'),
                      ],
                    ),
                    backgroundColor: _tempSelectedTheme
                        .color, // Đổi màu thông báo theo màu mới chọn
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    dynamicThemeColor, // Đổi màu nút Lưu động theo hệ thống
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Áp dụng chủ đề',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
