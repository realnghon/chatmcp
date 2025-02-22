import 'dart:async';
import 'package:chatmcp/utils/platform.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const List<String> requiredTables = ['chat', 'chat_message'];
  static const int currentVersion = 2;

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

    final DatabaseSchemaManager schemaManager = DatabaseSchemaManager();

    try {
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: currentVersion,
          onCreate: schemaManager.onCreate,
          onUpgrade: schemaManager.onUpgrade,
        ),
      );
      Logger.root.info('数据库连接成功');
      return db;
    } catch (e, stackTrace) {
      Logger.root.severe('数据库初始化错误: $e\n堆栈跟踪:\n$stackTrace');
      rethrow;
    }
  }
}

// 定义数据库迁移类
class DatabaseMigration {
  final int version;
  final List<String> sql;

  const DatabaseMigration({
    required this.version,
    required this.sql,
  });
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

/// 抽象命令类，封装每个版本升级所需执行的 SQL 语句
abstract class CommandScript {
  /// 利用 [Batch] 批量执行语句，避免多次调用数据库
  Future<void> execute(Batch batch);
}

/// 例如 v1 版本的建表逻辑
class CommandScriptV1 extends CommandScript {
  @override
  Future<void> execute(Batch batch) async {
    // 此处为初始建表的所有脚本
    Logger.root.info('开始创建表...');
    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        modelTEXT,
        createdAt datetime,
        updatedAt datetime
      )
    ''');
    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat_message(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId INTEGER,
        messageId TEXT,
        parentMessageId TEXT,
        body TEXT,
        createdAt datetime,
        updatedAt datetime,
        FOREIGN KEY (chatId) REFERENCES chat(id)
      )
    ''');
    Logger.root.info('表创建完成');
  }
}

/// 用来组织多个版本迁移脚本的管理类
class DatabaseSchemaManager {
  /// 将版本与对应的 CommandScript 做映射
  final Map<int, CommandScript> _commands = {};

  DatabaseSchemaManager() {
    // 这里将各版本的命令加入到 Map 中
    _commands[1] = CommandScriptV1();
    // 需要更多版本时，依次在此添加
  }

  /// 数据库创建时：创建表 (version=1)
  Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();
    // 从 version=1 开始依次执行，直到当前版本
    for (int v = 1; v <= version; v++) {
      final script = _commands[v];
      if (script != null) {
        await script.execute(batch);
      }
    }
    await batch.commit();
  }

  /// 数据库升级时：从 oldVersion+1 到 newVersion，依次执行脚本
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    final batch = db.batch();
    Logger.root.info('开始升级数据库... 从 $oldVersion 到 $newVersion');
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      final script = _commands[v];
      if (script != null) {
        await script.execute(batch);
      }
    }
    await batch.commit();
  }
}
