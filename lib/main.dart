import 'package:flutter/material.dart';
import 'main_shell.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'package:window_manager/window_manager.dart'; // 1. Import thư viện

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 2. Khởi tạo windowManager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720), // Kích thước mặc định khi mở app
    minimumSize: Size(
      1280,
      720,
    ), // KHẮC PHỤC: Kích thước tối thiểu không cho thu nhỏ hơn nữa
    center: true,
    title: "RJ Code POS",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ModernPOSApp());
}

class ModernPOSApp extends StatelessWidget {
  const ModernPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeProvider(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RJ Code POS',
          theme: AppThemeProvider().getThemeData(),
          home: const MainShell(),
        );
      },
    );
  }
}
