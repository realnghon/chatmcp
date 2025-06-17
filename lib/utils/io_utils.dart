import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getAppDir(String appName) async {
  final Directory appDir;
  if (Platform.isMacOS) {
    appDir = Directory(join(Platform.environment['HOME']!, 'Library', 'Application Support', appName));
  } else if (Platform.isWindows) {
    appDir = Directory(join(Platform.environment['APPDATA']!, appName));
  } else if (Platform.isLinux) {
    appDir = Directory(join(Platform.environment['HOME']!, '.local', 'share', appName));
  } else {
    appDir = await getApplicationDocumentsDirectory();
  }

  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }
  return appDir;
} 