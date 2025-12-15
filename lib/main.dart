import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'src/db/db.dart';
import 'src/providers/auth_provider.dart';
import 'src/screens/auth/landing_screen.dart';
import 'src/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await AppDatabase.instance.init();
  runApp(const TheGameAwardApp());
}

class TheGameAwardApp extends StatelessWidget {
  const TheGameAwardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'The Game Award',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LandingScreen(),
        routes: {
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}
