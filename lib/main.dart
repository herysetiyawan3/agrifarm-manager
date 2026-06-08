import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Indonesian Date formatting
  await initializeDateFormatting('id_ID', null);

  // 2. Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBre558g4LWEAyPmKMYijQRIkL4ILKomeQ",
          authDomain: "tani-hub.firebaseapp.com",
          projectId: "tani-hub",
          storageBucket: "tani-hub.firebasestorage.app",
          messagingSenderId: "277554551041",
          appId: "1:277554551041:web:b45b3d9ca2924be7266300",
          measurementId: "G-MKSK91W49Y",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 3. Initialize Notifications
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification service initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'AgriFarm Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Scaffold(
          body: Center(
            child: Text('Terjadi kesalahan sistem: $err'),
          ),
        ),
      ),
    );
  }
}
