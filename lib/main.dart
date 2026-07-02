import 'package:flutter/material.dart';
import 'pages/cai_dat/app_storage.dart';
import 'main_shell.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'pages/login_page.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  await windowManager.ensureInitialized();

  final String appTitle = AppStorage.getAppName();
  WindowOptions windowOptions = WindowOptions(
    size: const Size(1280, 720),
    minimumSize: const Size(1280, 720),
    center: true,
    title: appTitle,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Đọc token đã lưu để quyết định màn hình xuất phát ban đầu
  final String? token = AppStorage.getString('jwt_token');
  final String initialRoute = (token != null && token.isNotEmpty)
      ? '/home'
      : '/login';

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
          title: AppStorage.getAppName(),
          theme: AppThemeProvider().getThemeData(),
          initialRoute: initialRoute,
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainShell(),
          },
        );
      },
    );
  }
}
