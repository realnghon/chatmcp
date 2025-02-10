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
  static const int currentVersion = 2;

  // 定义数据库版本迁移脚本
  static final List<DatabaseMigration> migrations = [
    DatabaseMigration(
      version: 1,
      sql: [
        '''
        CREATE TABLE IF NOT EXISTS chat(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          createdAt datetime,
          updatedAt datetime
        )
        ''',
        '''
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
        '''
      ],
    ),
    DatabaseMigration(
      version: 2,
      sql: ['ALTER TABLE chat ADD COLUMN model TEXT'],
    ),
    // 后续版本可以继续在这里添加
  ];

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
          version: currentVersion,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
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
      // 执行初始版本的建表语句
      final initialMigration = migrations.first;
      for (var statement in initialMigration.sql) {
        await db.execute(statement);
        Logger.root.info('执行SQL: $statement');
      }
      Logger.root.info('数据库初始化完成');
    } catch (e, stackTrace) {
      Logger.root.severe('创建数据库表失败: $e\n堆栈跟踪:\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.root.info('数据库升级：从版本 $oldVersion 升级到 $newVersion');

    try {
      // 获取需要执行的迁移脚本
      final pendingMigrations = migrations
          .where((migration) =>
              migration.version > oldVersion && migration.version <= newVersion)
          .toList()
        ..sort((a, b) => a.version.compareTo(b.version));

      // 按顺序执行迁移脚本
      for (var migration in pendingMigrations) {
        Logger.root.info('执行版本 ${migration.version} 的迁移脚本');
        for (var statement in migration.sql) {
          await db.execute(statement);
          Logger.root.info('执行SQL: $statement');
        }
      }

      Logger.root.info('数据库升级完成');
    } catch (e, stackTrace) {
      Logger.root.severe('数据库升级失败: $e\n堆栈跟踪:\n$stackTrace');
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
