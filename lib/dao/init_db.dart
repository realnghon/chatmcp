import 'dart:async';
import 'package:ChatMcp/utils/platform.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const List<String> requiredTables = ['chat', 'chat_message'];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (kIsMobile) {
      databaseFactory = sqflite.databaseFactory;
    }

    final Directory appDataDir = await getAppDir('ChatMcp');
    final dbPath = join(appDataDir.path, 'chatmcp.db');

    Logger.root.fine('db path: $dbPath');
    Logger.root.fine('platform: ${Platform.operatingSystem}');

    try {
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
          onOpen: (db) async {
            try {
              await _ensureTablesExist(db);
            } catch (e, stackTrace) {
              Logger.root.severe('检查表存在时出错: $e\n堆栈跟踪:\n$stackTrace');
              rethrow;
            }
          },
        ),
      );
      Logger.root.info('数据库连接成功');
      return db;
    } catch (e, stackTrace) {
      Logger.root.severe('数据库初始化错误: $e\n堆栈跟踪:\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _ensureTablesExist(Database db) async {
    // 检查所有必需的表是否存在
    final tables = await db.query('sqlite_master',
        where:
            "type = 'table' AND name IN (${requiredTables.map((_) => '?').join(',')})",
        whereArgs: requiredTables);

    Logger.root.info('现有表: ${tables.length}, 需要的表: ${requiredTables.length}');
    Logger.root.info('已存在的表: ${tables.map((t) => t['name']).join(', ')}');

    final existingTableNames = tables.map((t) => t['name'] as String).toSet();
    final missingTables =
        requiredTables.where((t) => !existingTableNames.contains(t)).toList();

    if (missingTables.isNotEmpty) {
      Logger.root.info('缺少的表: ${missingTables.join(', ')}，开始创建...');
      await _createDB(db, 1);

      // 验证表是否创建成功
      final verifyTables = await db.query('sqlite_master',
          where:
              "type = 'table' AND name IN (${requiredTables.map((_) => '?').join(',')})",
          whereArgs: requiredTables);

      if (verifyTables.length != requiredTables.length) {
        throw Exception(
            '表创建失败，预期表数量: ${requiredTables.length}，实际创建: ${verifyTables.length}');
      }
      Logger.root.info('所有缺失的表已成功创建');
    } else {
      Logger.root.info('所有必需的表都已存在');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // 检查表是否已存在，如果存在则跳过
      for (var table in requiredTables) {
        final tableExists = await db.query('sqlite_master',
            where: "type = 'table' AND name = ?", whereArgs: [table]);

        if (tableExists.isEmpty) {
          // 获取对应表的创建语句
          final createStatement = sql
              .split(';')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => s.trim())
              .where((s) =>
                  s.toLowerCase().contains('create table') &&
                  s.toLowerCase().contains(table.toLowerCase()))
              .first;

          await db.execute(createStatement);
          Logger.root.info('创建表: $table');
        } else {
          Logger.root.info('表已存在，跳过创建: $table');
        }
      }

      Logger.root.info('数据库表检查/创建完成');
    } catch (e, stackTrace) {
      Logger.root.severe('创建数据库表失败: $e\n堆栈跟踪:\n$stackTrace');
      rethrow;
    }
  }
}

Future<void> initDb() async {
  try {
    Logger.root.info('开始初始化数据库...');
    final db = await DatabaseHelper.instance.database;
    // 验证表是否真的创建了
    final tables = await db.query('sqlite_master', where: "type = 'table'");
    Logger.root
        .info('数据库初始化完成，现有表: ${tables.map((t) => t['name']).join(', ')}');
  } catch (e, stackTrace) {
    Logger.root.severe('initDb 失败: $e\n堆栈跟踪:\n$stackTrace');
    rethrow;
  }
}

const sql = '''
CREATE TABLE IF NOT EXISTS chat(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    createdAt datetime,
    updatedAt datetime
);

CREATE TABLE IF NOT EXISTS chat_message(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chatId INTEGER,
    messageId TEXT,
    parentMessageId TEXT,
    body TEXT,
    createdAt datetime,
    updatedAt datetime,
    FOREIGN KEY (chatId) REFERENCES chat(id)
);
''';
