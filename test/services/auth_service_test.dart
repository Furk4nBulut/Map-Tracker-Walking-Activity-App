import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_tracker/firebase_options.dart'; // Ensure this file exists and is properly configured
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:flutter/material.dart';
import 'auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  DatabaseHelper,
  QuerySnapshot,
  QueryDocumentSnapshot,
  BuildContext
])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockDatabaseHelper mockDbHelper;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockBuildContext mockContext;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  });


  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockDbHelper = MockDatabaseHelper();
    mockGoogleSignIn = MockGoogleSignIn();
    mockContext = MockBuildContext();

    authService = AuthService();
  });

  group('AuthService Tests', () {
    test('Successful sign-up', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123'))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockDbHelper.insertUser(any)).thenAnswer((_) async => 1);

      await authService.signUp(mockContext, name: 'John', surname: 'Doe', email: 'test@example.com', password: 'password123');

      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123')).called(1);
      verify(mockDbHelper.insertUser(any)).called(1);
    });

    test('Sign-up with Firebase exception', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123'))
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await authService.signUp(mockContext, name: 'John', surname: 'Doe', email: 'test@example.com', password: 'password123');

      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123')).called(1);
    });

    test('Successful sign-in with existing local user', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();
      final localUser = LocalUser(email: 'test@example.com', firstName: 'John', lastName: 'Doe', password: 'password123');

      when(mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123'))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockDbHelper.getUserByEmail('test@example.com')).thenAnswer((_) async => localUser);
      when(mockDbHelper.updateUser(localUser)).thenAnswer((_) async => 1);

      await authService.signIn(mockContext, email: 'test@example.com', password: 'password123');

      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123')).called(1);
      verify(mockDbHelper.getUserByEmail('test@example.com')).called(1);
    });

    test('Sign-in with new local user', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123'))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockDbHelper.getUserByEmail('test@example.com')).thenAnswer((_) async => null);
      when(mockDbHelper.insertUser(any)).thenAnswer((_) async => 1);

      await authService.signIn(mockContext, email: 'test@example.com', password: 'password123');

      verify(mockDbHelper.insertUser(any)).called(1);
    });

    test('Successful Google sign-in', () async {
      final mockGoogleSignInAccount = MockGoogleSignInAccount();
      final mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn('mock_access_token');
      when(mockGoogleSignInAuthentication.idToken).thenReturn('mock_id_token');
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);

      final user = await authService.signInWithGoogle();

      expect(user, isNotNull);
      verify(mockGoogleSignIn.signIn()).called(1);
    });

    test('Successful sign-out', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
      when(mockDbHelper.logout()).thenAnswer((_) async => {});

      await authService.signOut(mockContext);

      verify(mockFirebaseAuth.signOut()).called(1);
      verify(mockDbHelper.logout()).called(1);
    });

    test('Synchronizing user activities from Firestore', () async {
      final mockUser = MockUser();
      final localUser = LocalUser(email: 'test@example.com', firstName: 'John', lastName: 'Doe', password: 'password123');
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final activityData = {
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'totalDistance': 1000.0,
        'elapsedTime': 3600,
        'averageSpeed': 16.67,
        'startPosition': {'latitude': 41.0082, 'longitude': 28.9784},
        'endPosition': {'latitude': 41.0089, 'longitude': 28.9789},
        'route': [
          {'latitude': 41.0082, 'longitude': 28.9784},
          {'latitude': 41.0089, 'longitude': 28.9789}
        ]
      };

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('mock_uid');
      when(mockFirestore.collection('user').doc('mock_uid').collection('activities').get())
          .thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.data()).thenReturn(activityData);
      when(mockDbHelper.insertActivity(any)).thenAnswer((_) async => 1);

      await authService.syncUserActivities(mockContext, localUser);

      verify(mockDbHelper.insertActivity(any)).called(1);
    });
  });
}