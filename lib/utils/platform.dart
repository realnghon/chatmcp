import 'dart:io' show Platform;

final bool kIsDesktop =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

final bool kIsMobile = Platform.isAndroid || Platform.isIOS;
