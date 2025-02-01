import 'package:flutter_test/flutter_test.dart';
import 'package:map_tracker/model/user_model.dart';  // LocalUser sınıfının bulunduğu dosya

void main() {
  group('LocalUser Tests', () {
    late LocalUser user;

    setUp(() {
      user = LocalUser(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        password: 'password123',
      );
    });

    test('toMap should return a valid map', () {
      final map = user.toMap();

      expect(map['id'], 1);
      expect(map['firstName'], 'John');
      expect(map['lastName'], 'Doe');
      expect(map['email'], 'john.doe@example.com');
      expect(map['password'], 'password123');
    });

    test('fromMap should create a valid LocalUser object', () {
      final map = user.toMap();
      final newUser = LocalUser.fromMap(map);

      expect(newUser.id, 1);
      expect(newUser.firstName, 'John');
      expect(newUser.lastName, 'Doe');
      expect(newUser.email, 'john.doe@example.com');
      expect(newUser.password, 'password123');
    });

    test('getters should return correct values', () {
      expect(user.getId, 1);
      expect(user.getFirstName, 'John');
      expect(user.getLastName, 'Doe');
      expect(user.getEmail, 'john.doe@example.com');
      expect(user.getPassword, 'password123');
    });

    test('setters should update values correctly', () {
      user.setFirstName = 'Jane';
      user.setLastName = 'Smith';
      user.setEmail = 'jane.smith@example.com';
      user.setPassword = 'newpassword123';

      expect(user.firstName, 'Jane');
      expect(user.lastName, 'Smith');
      expect(user.email, 'jane.smith@example.com');
      expect(user.password, 'newpassword123');
    });
  });
}