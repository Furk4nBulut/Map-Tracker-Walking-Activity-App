import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_tracker/model/user_model.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'user';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'furkan.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE $tableName(id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, email TEXT, password TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertUser(LocalUser user) async {
    final db = await database;
    await db.insert(
      tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalUser?> getUserByEmail(String email) async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: "email = ?",
      whereArgs: [email],
    );
    if (users.isNotEmpty) {
      return LocalUser.fromMap(users.first);
    } else {
      return null;
    }
  }

  Future<bool> login(LocalUser user) async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: "email = ? AND password = ?",
      whereArgs: [user.email, user.password],
    );
    if (users.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', users.first['id'] as int);
      return true;
    }
    return false;
  }

  Future<LocalUser?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? currentUserId = prefs.getInt('currentUserId');
    if (currentUserId != null) {
      final db = await database;
      List<Map<String, dynamic>> users = await db.query(
        tableName,
        where: "id = ?",
        whereArgs: [currentUserId],
      );
      if (users.isNotEmpty) {
        return LocalUser.fromMap(users.first);
      }
    }
    return null;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
  }

  // update student method
  Future<int> updateUser(LocalUser user) async {
    final db = await database;
    return await db.update(
      tableName,
      user.toMap(),
      where: "id = ?",
      whereArgs: [user.id],
    );
  }
}