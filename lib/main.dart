import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/recuperar_screen.dart';
import 'screens/tecnico/tecnico_home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar notificaciones locales
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
 await flutterLocalNotificationsPlugin.initialize(
  settings: initSettings,
  onDidReceiveNotificationResponse: (NotificationResponse details) {},
);

  // Solicitar permisos FCM
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Mostrar notificación cuando app está en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notificación recibida: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
  id: 0,
  title: message.notification!.title,
  body: message.notification!.body,
  notificationDetails: const NotificationDetails(
    android: AndroidNotificationDetails(
      'emergencias_channel',
      'Emergencias',
      channelDescription: 'Notificaciones de emergencias vehiculares',
      importance: Importance.max,
      priority: Priority.high,
    ),
  ),
);
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmergenciasVial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/recuperar': (context) => const RecuperarScreen(),
        '/tecnico-home': (context) => const TecnicoHomeScreen(),
      },
    );
  }
}