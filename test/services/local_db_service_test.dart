import 'package:flutter_test/flutter_test.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late DatabaseHelper databaseHelper;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() async {
    mockSharedPreferences = MockSharedPreferences();
    databaseHelper = DatabaseHelper();

    // Mock SharedPreferences.getInstance()
    when(() => mockSharedPreferences.setInt(any(), any()))
        .thenAnswer((_) async => true);

    // `SharedPreferences.getInstance()` yerine mock'ı kullan
    SharedPreferences.setMockInitialValues({});
  });

  // Veritabanı fabrikasını FFI ile başlat
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await databaseHelper.close(); // Ensure db is closed after the test
  });

  test('insertUser ve getUserByEmail işlevlerini test et', () async {
    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );

    // Kullanıcıyı veritabanına ekle
    await databaseHelper.insertUser(user);

    // Kullanıcıyı e-posta ile sorgula
    LocalUser? retrievedUser = await databaseHelper.getUserByEmail('furkan@example.com');

    // Kullanıcıyı doğrula
    expect(retrievedUser, isNotNull);
    expect(retrievedUser?.email, 'furkan@example.com');
  });

  test('insertActivity ve getActivities işlevlerini test et', () async {
    // Veritabanı açıldığından emin olun
    final db = await databaseHelper.database;

    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );
    await databaseHelper.insertUser(user);

    // Aktivite oluştur
    Activity activity1 = Activity(
      id: '1',
      user: user,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 1)),
      totalDistance: 10.5,
      elapsedTime: 3600,
      averageSpeed: 10.5,
      startPositionLat: 40.7128,
      startPositionLng: -74.0060,
      endPositionLat: 40.7308,
      endPositionLng: -73.9352,
      route: [LatLng(40.7128, -74.0060), LatLng(40.7308, -73.9352)],
    );

    Activity activity2 = Activity(
      id: '2',
      user: user,
      startTime: DateTime.now().add(Duration(hours: 1)),  // İkinci aktiviteyi bir saat sonra oluşturuyoruz
      endTime: DateTime.now().add(Duration(hours: 2)),
      totalDistance: 15.0,
      elapsedTime: 7200,
      averageSpeed: 7.5,
      startPositionLat: 40.7308,
      startPositionLng: -73.9352,
      endPositionLat: 40.7128,
      endPositionLng: -74.0060,
      route: [LatLng(40.7308, -73.9352), LatLng(40.7128, -74.0060)],
    );

    // Aktiviteyi veritabanına ekle
    await databaseHelper.insertActivity(activity1);
    await databaseHelper.insertActivity(activity2);

    // Aktiviteyi sorgula
    List<Activity> activities = await databaseHelper.getActivities();

    // Aktiviteyi doğrula
    expect(activities, isNotEmpty);
    expect(activities.length, 2); // İki aktivite olmalı
    expect(activities.first.id, '2');  // En son eklenen aktivite ilk sırada olmalı
  });



  test('login işlevini test et', () async {
    // Veritabanı bağlantısını açmaya zorla
    final db = await databaseHelper.database;

    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );
    await databaseHelper.insertUser(user);

    // Login işlemi yap
    bool success = await databaseHelper.login(user);

    // Login başarısını doğrula
    expect(success, true);
  });

  test('getCurrentUser işlevini test et', () async {
    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );
    await databaseHelper.insertUser(user);

    // Login işlemi yap
    await databaseHelper.login(user);

    // Mevcut kullanıcıyı sorgula
    LocalUser? currentUser = await databaseHelper.getCurrentUser();

    // Mevcut kullanıcıyı doğrula
    expect(currentUser, isNotNull);
    expect(currentUser?.email, 'furkan@example.com');
  });

  test('logout işlevini test et', () async {
    // Kullanıcı oluştur
    final user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );

    // Kullanıcıyı veritabanına ekle
    await databaseHelper.insertUser(user);

    // Kullanıcı giriş yapsın
    await databaseHelper.login(user);

    // Logout işlemi yap
    await databaseHelper.logout();

    // SharedPreferences'tan kullanıcı ID'sinin silindiğini kontrol et
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('currentUserId');

    // Kullanıcının çıkış yaptığını doğrula
    expect(currentUserId, isNull);
  });


  test('getUserActivities işlevini test et', () async {
    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );
    await databaseHelper.insertUser(user);

    // Aktivite oluştur
    Activity activity1 = Activity(
      id: '1',
      user: user,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 1)),
      totalDistance: 10.5,
      elapsedTime: 3600,
      averageSpeed: 10.5,
      startPositionLat: 40.7128,
      startPositionLng: -74.0060,
      endPositionLat: 40.7308,
      endPositionLng: -73.9352,
      route: [LatLng(40.7128, -74.0060), LatLng(40.7308, -73.9352)],
    );

    Activity activity2 = Activity(
      id: '2',
      user: user,
      startTime: DateTime.now().add(Duration(days: 1)),
      endTime: DateTime.now().add(Duration(days: 1, hours: 1)),
      totalDistance: 12.5,
      elapsedTime: 4500,
      averageSpeed: 12.5,
      startPositionLat: 40.7308,
      startPositionLng: -73.9352,
      endPositionLat: 40.7128,
      endPositionLng: -74.0060,
      route: [LatLng(40.7308, -73.9352), LatLng(40.7128, -74.0060)],
    );

    // Aktiviteyi veritabanına ekle
    await databaseHelper.insertActivity(activity1);
    await databaseHelper.insertActivity(activity2);

    // Kullanıcıya ait aktiviteleri sorgula
    List<Activity> activities = await databaseHelper.getUserActivities(user.id!);

    // Aktivite listesini doğrula
    expect(activities, isNotEmpty);
    expect(activities.length, 2);

    // Aktivite sıralamasını kontrol et
    expect(activities[0].id, '2');  // En yeni aktivite önce gelir
    expect(activities[1].id, '1');  // Eski aktivite sonra gelir
  });


  test('getActivityById işlevini test et', () async {
    // Kullanıcı oluştur
    LocalUser user = LocalUser(
      id: 1,
      firstName: 'Furkan',
      lastName: 'Bulut',
      email: 'furkan@example.com',
      password: 'password123',
    );
    await databaseHelper.insertUser(user);

    // Aktivite oluştur
    Activity activity1 = Activity(
      id: '1',
      user: user,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 1)),
      totalDistance: 10.5,
      elapsedTime: 3600,
      averageSpeed: 10.5,
      startPositionLat: 40.7128,
      startPositionLng: -74.0060,
      endPositionLat: 40.7308,
      endPositionLng: -73.9352,
      route: [LatLng(40.7128, -74.0060), LatLng(40.7308, -73.9352)],
    );

    // Aktiviteyi veritabanına ekle
    await databaseHelper.insertActivity(activity1);

    // Aktiviteyi id ile sorgula
    Activity? retrievedActivity = await databaseHelper.getActivityById('1');

    // Aktiviteyi doğrula
    expect(retrievedActivity, isNotNull);
    expect(retrievedActivity?.id, '1');  // Beklenen ID '1'
  });
}
