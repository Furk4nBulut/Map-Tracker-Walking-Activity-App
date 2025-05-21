import 'package:get_it/get_it.dart';
import '../../../services/auth_service.dart';
import '../../../services/provider/auth_provider.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerSingleton<AuthProvider>(
    AuthProvider(locator.get<AuthService>()),
  );
}
