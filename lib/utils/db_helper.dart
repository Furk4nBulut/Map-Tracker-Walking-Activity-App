import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static final DBHelper instance = DBHelper._privateConstructor();

  DBHelper._privateConstructor();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    // Veritabanının yerini bul
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'tracker.db'),
      onCreate: (db, version) async {
        // Tablo oluşturma
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            surname TEXT,
            email TEXT,
            password TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<int> insertUser({required String name, required String surname, required String email, required String password}) async {
    final db = await instance.database;
    return await db!.insert('user', {
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db!.query('user');
  }

  Future<void> deleteUsers() async {
    final db = await instance.database;
    await db!.delete('user');
  }
}
