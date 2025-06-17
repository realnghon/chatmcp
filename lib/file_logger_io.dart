import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:chatmcp/utils/io_utils.dart';

class FileLogger {
  static File? _logFile;
  static IOSink? _logSink;

  static Future<void> initLogFile() async {
    try {
      final Directory appDir = await getAppDir('ChatMcp');
      final logDir = Directory(path.join(appDir.path, 'logs'));

      // Ensure log directory exists
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Use date as log filename
      final now = DateTime.now();
      final fileName = 'app_${now.year}-${now.month}-${now.day}.log';
      _logFile = File(path.join(logDir.path, fileName));

      // Open file in append mode
      _logSink = _logFile?.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  static void closeLogFile() {
    _logSink?.flush();
    _logSink?.close();
  }

  static void writeToFile(String message) {
    _logSink?.writeln('${DateTime.now()} $message');
  }
} 