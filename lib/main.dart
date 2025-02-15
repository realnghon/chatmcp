import 'package:ChatMcp/dao/init_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart' as wm;
import './logger.dart';
import './page/layout/layout.dart';
import './provider/provider_manager.dart';
import 'package:logging/logging.dart';
import 'page/layout/sidebar.dart';
import 'utils/platform.dart';
import 'package:ChatMcp/provider/settings_provider.dart';
import 'utils/color.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeLogger();

  if (!kIsWeb) {
    // 移动端不支持
    // if (!kIsDesktop) {
    //   await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    // }

    // 获取一个可用的端口
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();

    if (!kIsDesktop) {
      final InAppLocalhostServer localhostServer =
          InAppLocalhostServer(documentRoot: 'assets/sandbox', port: port);

      ProviderManager.settingsProvider.updateSandboxServerPort(port: port);

      // start the localhost server
      await localhostServer.start();

      Logger.root.info('Sandbox server started @ http://localhost:$port');
    }
  }

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
      // backgroundColor: Colors.transparent,
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'ChatMcp',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: _getThemeMode(settings.generalSetting.theme),
          home: Scaffold(
            drawer: kIsMobile
                ? Builder(
                    builder: (BuildContext context) => Theme(
                      data: Theme.of(context),
                      child: Container(
                        width: 250,
                        color: AppColors.getThemeBackgroundColor(context),
                        child: SafeArea(
                          child: SidebarPanel(
                            onToggle: () {},
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            body: LayoutPage(),
          ),
        );
      },
    );
  }

  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
