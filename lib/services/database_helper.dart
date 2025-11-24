import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sightsync.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users(
        user_id INTEGER PRIMARY KEY,
        email TEXT,
        password_hash TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Settings(
        setting_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        brightness INTEGER,
        volume INTEGER,
        voice_control INTEGER,
        single_press_map TEXT,
        double_press_map TEXT,
        wifi_ssid TEXT,
        FOREIGN KEY(user_id) REFERENCES Users(user_id)
      )
    ''');
    
    // MediaFiles table omitted for now as per immediate requirements, but can be added here.
  }

  // User Methods
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('Users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(int id) async {
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
    return await db.insert('Settings', settings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SettingsModel?> getSettings(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Settings', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      return SettingsModel.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> updateSettings(SettingsModel settings) async {
    Database db = await database;
    return await db.update(
      'Settings',
      settings.toMap(),
      where: 'user_id = ?',
      whereArgs: [settings.userId],
    );
  }
}
