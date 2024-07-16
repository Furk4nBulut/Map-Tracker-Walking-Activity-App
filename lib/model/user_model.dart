class LocalUser {
  final int? id;
  String firstName;
  String lastName;
  String email;
  String password;

  LocalUser({
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
  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      password: map['password'],
    );
  }
  // create getter setter for user
  String get getFirstName => firstName;
  String get getLastName => lastName;
  String get getEmail => email;
  String get getPassword => password;
  int? get getId => id;

  // create setter for user
  set setFirstName(String firstName) => this.firstName = firstName;
  set setLastName(String lastName) => this.lastName = lastName;
  set setEmail(String email) => this.email = email;
  set setPassword(String password) => this.password = password;



}
