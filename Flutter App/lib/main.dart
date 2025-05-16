import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/store_service.dart';
import 'state/store_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/stores/store_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(baseUrl: 'http://10.0.2.2:3000');
    final storeService = StoreService(authService: authService);
    final storeState = StoreState(storeService);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCI Student Portal',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: LoginScreen(authService: authService),
      routes: {
        '/register': (context) => RegisterScreen(authService: authService),
        '/change_password': (context) =>
            ChangePasswordScreen(authService: authService),
        '/stores': (context) => StoreListScreen(
              storeState: storeState,
              authService: authService,
            ),
      },
    );
  }
}
