import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'main_shell.dart';
import 'pages/cai_dat/app_storage.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'pages/login_page.dart';

void main() async {
  // 1. Đảm bảo Flutter Core được kích hoạt đầu tiên
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Trình quản lý cửa sổ hiển thị Desktop ngay lập tức để tránh lỗi Treo OS
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(1280, 720),
    center: true,
    title: "RJ Code POS",
  );

  // Hiển thị cửa sổ Windows lên trước để người dùng thấy ứng dụng phản hồi nhanh
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 3. SAU KHI CỬA SỔ HIỆN LÊN: Khởi tạo bộ nhớ ổ đĩa AppStorage của bạn
  await AppStorage.init();

  // 4. Đọc token từ bộ nhớ để quyết định Route xuất phát ban đầu
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');
  final String initialRoute = (token != null && token.isNotEmpty)
      ? '/home'
      : '/login';

  // 5. Khởi chạy cây Widget chính của ứng dụng
  runApp(ModernPOSApp(initialRoute: initialRoute));
}

class ModernPOSApp extends StatelessWidget {
  final String initialRoute;

  const ModernPOSApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeProvider(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RJ Code POS',
          theme: AppThemeProvider()
              .getThemeData(), // Nạp mượt mà hệ thống màu động của bạn

          initialRoute: initialRoute,

          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) =>
                const MainShell(), // Điều hướng vào khung menu Sidebar điều hướng chính
          },
        );
      },
    );
  }
}
