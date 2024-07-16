import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/model/activity_model.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'user';
  static const String activityTable = 'activities';
  LocalUser? localUser;

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
      join(path, 'saas.db'),
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE $tableName(id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, email TEXT, password TEXT)",
        );
        db.execute(
          "CREATE TABLE $activityTable(id INTEGER PRIMARY KEY, userId INTEGER, startTime TEXT, endTime TEXT, totalDistance REAL, elapsedTime INTEGER, averageSpeed REAL, startPositionLat REAL, startPositionLng REAL, endPositionLat REAL, endPositionLng REAL, route TEXT)",
        );
      },
      version: 1,
    );
  }

  // User CRUD Operations
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

  Future<int> updateUser(LocalUser user) async {
    final db = await database;
    return await db.update(
      tableName,
      user.toMap(),
      where: "id = ?",
      whereArgs: [user.id],
    );
  }

  // Activity CRUD Operations
  Future<void> insertActivity(Activity activity) async {
    final db = await database;

    await db.insert(
      activityTable,
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Activity>> getActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(activityTable);
    List<Activity> activities = [];
    for (var map in maps) {
      LocalUser? user = await getUserById(map['userId']);
      if (user != null) {
        activities.add(Activity.fromMap(map, user));
      }
    }
    return activities;
  }
  // get acitivty by id
  Future<Activity?> getActivityById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> activities = await db.query(
      activityTable,
      where: "id = ?",
      whereArgs: [id],
    );
    if (activities.isNotEmpty) {
      LocalUser? user = await getUserById(activities.first['userId']);
      if (user != null) {
        return Activity.fromMap(activities.first, user);
      }
    }
    return null;
  }

  // DatabaseHelper içine eklenecek metod
  Future<bool> checkActivityExists(String activityId) async {
    final db = await database;
    var res = await db.query(activityTable,
        where: "id = ?", whereArgs: [activityId]);
    return res.isNotEmpty;
  }


  // Get user activities
  Future<List<Activity>> getUserActivities(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      activityTable,
      where: "userId = ?",
      whereArgs: [userId],
      orderBy: "startTime DESC",
    );
    List<Activity> activities = [];
    LocalUser? user = await getUserById(userId);
    if (user != null) {
      for (var map in maps) {
        activities.add(Activity.fromMap(map, user));
      }
    }
    return activities;
  }

  Future<LocalUser?> getUserById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    if (users.isNotEmpty) {
      return LocalUser.fromMap(users.first);
    } else {
      return null;
    }
  }
}
