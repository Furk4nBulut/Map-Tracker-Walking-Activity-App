import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:map_tracker/model/user_model.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'user';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // Eğer _database null ise, onu başlat
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    // Veritabanı yolunu al
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

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUsers(String email) async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: "email = ?",
      whereArgs: [email],
    );
    if (users.isNotEmpty) {
      return User.fromMap(users.first);
    } else {
      return null;
    }
  }

Future <bool> login(User user) async {
    final db = await initDatabase();
    List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: "email = ? AND password = ?",
      whereArgs: [user.email, user.password],
    );
    if (users.isNotEmpty) {
      return true;
    } else {
      return false;
    }
}
}
