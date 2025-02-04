import 'package:ChatMcp/dao/init_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './logger.dart';
import './page/layout/layout.dart';
import './provider/provider_manager.dart';
import 'package:logging/logging.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'page/layout/sidebar.dart';
import 'utils/platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 只在桌面平台初始化窗口管理器
  if (kIsDesktop) {
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
    await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions,
        () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  try {
    initializeLogger();
    await Future.wait([
      ProviderManager.init(),
      initDb(),
    ]);

    var app = MyApp();

    runApp(
      MultiProvider(
        providers: [
          ...ProviderManager.providers,
        ],
        child: app,
      ),
    );
  } catch (e, stackTrace) {
    Logger.root.severe('Main 错误: $e\n堆栈跟踪:\n$stackTrace');
  }
}

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
      home: Scaffold(
        drawer: kIsMobile
            ? Container(
                width: 250,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: SidebarPanel(
                    onToggle: () {},
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: LayoutPage(),
        ),
      ),
    );
  }
}
