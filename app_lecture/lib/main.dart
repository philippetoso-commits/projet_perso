import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/word.dart';
import 'models/profile.dart';
import 'models/word_progress.dart';
import 'screens/home_screen.dart';
import 'screens/profile_select_screen.dart';
import 'services/data_loader.dart';
import 'services/profile_service.dart';
import 'services/syllabary_service.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(WordAdapter());
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(WordProgressAdapter());

    final logService = LogService();
    logService.add("🚀 App Startup...");

    final dataLoader = DataLoader();
    dataLoader.onLog = (m) => logService.add(m);
    await dataLoader.initData();

    final profileService = ProfileService.instance;
    await profileService.ensureOpen();
    await SyllabaryService.instance.ensureLoaded();
  } catch (e, stack) {
    LogService().add("CRITICAL ERROR DURING STARTUP: $e");
    print(stack);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyllaboJeux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const _InitialScreen(),
    );
  }
}

/// Affiche le choix de profil si aucun n'est sélectionné, sinon l'accueil.
class _InitialScreen extends StatelessWidget {
  const _InitialScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  static Future<Widget> _resolveHome() async {
    final profileService = ProfileService.instance;
    await profileService.ensureOpen();
    final current = profileService.getCurrentProfile();
    if (current != null) return const HomeScreen();
    return const ProfileSelectScreen(fromSettings: false);
  }
}
