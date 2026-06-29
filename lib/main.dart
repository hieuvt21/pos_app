import 'package:flutter/material.dart';
import 'pages/cai_dat/app_storage.dart';
import 'main_shell.dart';
import 'pages/cai_dat/cai_dat_cua_hang/theme_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(1280, 720),
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
