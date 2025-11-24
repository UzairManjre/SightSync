import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // We change the filename to force a fresh DB creation with new schema
    String path = join(await getDatabasesPath(), 'sightsync_v3.db');
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

  // User Methods
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('Users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Users', where: 'user_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // Settings Methods
  Future<int> insertSettings(SettingsModel settings) async {
    Database db = await database;
    // Convert boolean to int for SQLite
    Map<String, dynamic> map = settings.toMap();
    map['voice_control_enabled'] = settings.voiceControl ? 1 : 0;

    return await db.insert('Settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SettingsModel?> getSettings(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Settings', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      // Convert SQLite int back to boolean
      Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
      map['voice_control_enabled'] = (map['voice_control_enabled'] == 1);
      return SettingsModel.fromMap(map);
    }
    return null;
  }
}