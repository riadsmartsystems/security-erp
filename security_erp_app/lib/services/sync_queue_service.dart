import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'sync_queue.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT,
            method TEXT,
            body TEXT,
            file_path TEXT,
            timestamp INTEGER,
            attempts INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sync_queue ADD COLUMN file_path TEXT');
        }
      },
    );
  }

  Future<void> enqueue(String url, String method, Map<String, dynamic> body, {String? filePath}) async {
    final db = await database;
    await db.insert('sync_queue', {
      'url': url,
      'method': method,
      'body': jsonEncode(body),
      'file_path': filePath,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }


  Future<void> enqueue(String url, String method, Map<String, dynamic> body, {String? filePath}) async {
    final db = await database;
    await db.insert('sync_queue', {
      'url': url,
      'method': method,
      'body': jsonEncode(body),
      'filePath': filePath,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementAttempts(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?', [id]);
  }

  Future<int> getQueueCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_queue')) ?? 0;
  }
}

final syncQueue = SyncQueueService();
