import 'package:ChatMcp/dao/init_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './logger.dart';
import './page/layout/layout.dart';
import './provider/provider_manager.dart';
import 'package:logging/logging.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await WindowManagerPlus.ensureInitialized(0);

  // 设置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // 等待窗口准备好并显示
  await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });

  try {
    initializeLogger();
    await Future.wait([
      ProviderManager.init(),
      initDb(),
    ]);

    runApp(
      MultiProvider(
        providers: [
          ...ProviderManager.providers,
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    Logger.root.severe('Main 错误: $e\n堆栈跟踪:\n$stackTrace');
  }
}

// 在应用退出时清理资源
Future<void> cleanupResources() async {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatMcp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: LayoutPage(),
        ),
      ),
    );
  }
}
