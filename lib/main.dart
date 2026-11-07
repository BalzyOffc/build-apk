import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'owner_page.dart'; // <--- Import OwnerPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIGHT',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Rajdhani-Regular',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        colorScheme: ColorScheme.light().copyWith(
          primary: Colors.black,
          secondary: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listBugGlobal: List<Map<String, dynamic>>.from(args['listBugGlobal'] ?? []),
                listBugGroup: List<Map<String, dynamic>>.from(args['listBugGroup'] ?? []),
                listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listBugGlobal: List<Map<String, dynamic>>.from(args['listBugGlobal'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'], // Pastikan keyToken ada di args
              ),
            );

          // Admin page removed - use Owner and Seller pages only
        // --- ROUTE BARU: OWNER ---
          case '/owner':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OwnerPage(
                sessionKey: args['sessionKey'], // Pastikan sessionKey ada di args
                username: args['username'], // Pastikan username ada di args
                currentUserRole: args['role'] ?? 'member',
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text("404 - Not Found")),
              ),
            );
        }
      },
    );
  }
}