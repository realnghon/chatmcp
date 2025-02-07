import 'package:ChatMcp/dao/init_db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart' as wm;
import './logger.dart';
import './page/layout/layout.dart';
import './provider/provider_manager.dart';
import 'package:logging/logging.dart';
import 'page/layout/sidebar.dart';
import 'utils/platform.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  initializeLogger();

  WidgetsFlutterBinding.ensureInitialized();

  // if (kIsMobile) {
  //   await FlutterStatusbarcolor.setStatusBarColor(Colors.green[400]!);
  //   if (useWhiteForeground(Colors.green[400]!)) {
  //     FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
  //   } else {
  //     FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
  //   }
  // }

  if (kIsDesktop) {
    await wm.windowManager.ensureInitialized();

    final wm.WindowOptions windowOptions = wm.WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle:
          kIsLinux ? wm.TitleBarStyle.normal : wm.TitleBarStyle.hidden,
    );

    await wm.windowManager.waitUntilReadyToShow(windowOptions, () async {
      await wm.windowManager.show();
      await wm.windowManager.focus();
    });
  }

  try {
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
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'ChatMcp',
      theme: ThemeData(
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
        body: LayoutPage(),
      ),
    );
  }
}
