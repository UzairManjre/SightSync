import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Web doesn't support sqflite out of the box
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sightsync_v4.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users(
        user_id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        avatar_url TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Settings(
        setting_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        brightness INTEGER,
        volume INTEGER,
        voice_control_enabled INTEGER,
        single_press_action TEXT,
        double_press_action TEXT,
        wifi_ssid TEXT,
        last_synced_at TEXT,
        FOREIGN KEY(user_id) REFERENCES Users(user_id)
      )
    ''');
  }

  // --- User Methods ---
  Future<int> insertUser(UserModel user) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.insert('Users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String id) async {
    if (kIsWeb) return null;
    Database? db = await database;
    List<Map<String, dynamic>> maps = await db!.query('Users', where: 'user_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  // --- Settings Methods ---
  Future<int> insertSettings(SettingsModel settings) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    Map<String, dynamic> map = settings.toLocalJson();
    // Ensure boolean conversion happens in toLocalJson or here if needed
    return await db!.insert('Settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SettingsModel?> getSettings(String userId) async {
    if (kIsWeb) return null;
    Database? db = await database;
    List<Map<String, dynamic>> maps = await db!.query('Settings', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      return SettingsModel.fromMap(maps.first);
    }
    return null;
  }
}