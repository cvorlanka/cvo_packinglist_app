import 'package:flutter/material.dart';
import 'package:packinglist_app/components/msauth_controller/test_aad_o_auth_controller.dart';
// import 'package:packinglist_app/pages/loading_page.dart';
import 'package:packinglist_app/pages/login_page.dart';
import 'package:packinglist_app/pages/home_page.dart';
import 'package:packinglist_app/pages/packing_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AadOAuthController.mainNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        // '/': (context) => const LoadingPage(),
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/packing': (context) => const PackingPage(),
      },
    );
  }
}
