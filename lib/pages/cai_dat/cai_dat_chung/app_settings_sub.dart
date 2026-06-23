import 'package:flutter/material.dart';
import '../../../services/app_config.dart'; // Đảm bảo đúng đường dẫn tới file dịch vụ của bạn

class AppSettingsSubPage extends StatefulWidget {
  const AppSettingsSubPage({super.key});

  @override
  State<AppSettingsSubPage> createState() => _AppSettingsSubPageState();
}

class _AppSettingsSubPageState extends State<AppSettingsSubPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = AppConfig().serverIp;
    _portController.text = AppConfig().serverPort;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveSettings(Color activeThemeColor) {
    AppConfig().updateConfig(_ipController.text, _portController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu cấu hình máy chủ: ${AppConfig().baseUrl}'),
        backgroundColor:
            activeThemeColor, // Đổi màu nền SnackBar theo màu chủ đề động
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo động hiện tại từ hệ thống Theme
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= HEADER TIÊU ĐỀ SUB-PAGE =================
        Row(
          children: [
            Icon(
              Icons.dns_rounded,
              color: dynamicThemeColor,
              size: 22,
            ), // Đổi màu icon tiêu đề theo theme
            const SizedBox(width: 10),
            const Text(
              'Cấu hình Kết nối Máy chủ',
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
          'Thiết lập thông số mạng địa phương (IP và Cổng kết nối) để ứng dụng POS kết nối đồng bộ dữ liệu tới hệ thống máy chủ cơ sở dữ liệu SQL Server Backend.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const Divider(height: 32, color: Color(0xFFF1F5F9)),

        // ================= KHUNG NHẬP LIỆU (FORM) =================
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ IP máy chủ (IPv4)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ipController,
                    decoration: _inputDecoration(
                      'Ví dụ: 192.168.1.15',
                      dynamicThemeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cổng kết nối (Port)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _portController,
                    decoration: _inputDecoration(
                      'Ví dụ: 5000',
                      dynamicThemeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Spacer(),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),

        // ================= ĐÁY TRANG - NÚT ĐIỀU HƯỚNG BẤM LƯU =================
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _ipController.text = AppConfig().serverIp;
                  _portController.text = AppConfig().serverPort;
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
              onPressed: () => _saveSettings(dynamicThemeColor),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    dynamicThemeColor, // Đổi màu nền nút Lưu cấu hình động theo theme
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
                'Lưu cấu hình',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Hàm sinh giao diện chuẩn hóa cho khung nhập liệu có viền focus đổi màu động
  InputDecoration _inputDecoration(String hint, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: focusColor,
          width: 1.5,
        ), // Viền sẽ tự động đổi màu khi người dùng click gõ chữ
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
