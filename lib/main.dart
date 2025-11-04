import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/features/home/presentation/pages/home_guest.dart';
import 'package:provider/provider.dart';
import 'package:huystore/core/services/notification_router.dart';
import 'package:huystore/features/home/presentation/pages/home_page.dart';
import 'package:huystore/features/auth/presentation/pages/login_page.dart';
import 'package:huystore/features/auth/presentation/pages/register.dart';
import 'core/services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Thông báo nền: ${message.notification?.title}");
}
// Giả lập trạng thái login và guest
bool isLoggedIn = false;
bool isGuest = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'lib/core/config/.env.development');
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    print("✅ ENV loaded: ${dotenv.env}");
  } catch (e) {
    print("❌ Failed to load ENV: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => NotificationService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HuyStore',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ),
     home: const SplashWrapper(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomeScreen(),
        '/guest_home': (_) => const HomeGuestPage(),
        '/register': (_) => const RegisterPage(), 
      },
    );
  }
}
class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ở đây kiểm tra trạng thái login hoặc guest rồi điều hướng tương ứng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (isGuest) {
        Navigator.pushReplacementNamed(context, '/guest');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}