class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  // User modelini Map'e dönüştüren yöntem
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    };
  }

  // Map'ten User modeline dönüştüren yöntem
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      password: map['password'],
    );
  }
}
