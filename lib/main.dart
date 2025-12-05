import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'HomeScreen/HomeScreen.dart';
import 'Provider/HomeProvider.dart';
import 'Screens/LoginScreen.dart';
import 'Screens/SplashScreen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Flutter Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Tracks the currently open chat phone to skip notifications
String? _currentOpenChatId;
/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  if (_currentOpenChatId != message.data['chatId']) {
    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }
}


/// Show local notification
void showLocalNotification(String title, String body) {
  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    ),
  );
}

/// Exit popup wrapper
Future<bool> showExitPopup(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Exit App?'),
      content: const Text('Do you really want to exit the app?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes')),
      ],
    ),
  ) ??
      false;
}

class ExitWrapper extends StatelessWidget {
  final Widget child;
  const ExitWrapper({required this.child, Key? key}) : super(key: key);



/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  if (_currentOpenChatId != message.data['chatId']) {
    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }
}


/// Show local notification
void showLocalNotification(String title, String body) {
  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    ),
  );
}

/// Exit popup wrapper
Future<bool> showExitPopup(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Exit App?'),
      content: const Text('Do you really want to exit the app?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes')),
      ],
    ),
  ) ??
      false;
}

class ExitWrapper extends StatelessWidget {
  final Widget child;
  const ExitWrapper({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool willExit = await showExitPopup(context);
        return willExit;
      },
      child: child,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request notification permissions
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications init
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings,
      onDidReceiveNotificationResponse: (payload) {
        // Handle tap on notification
        final data = payload?.payload;
        if (data != null && navigatorKey.currentState != null) {
          navigatorKey.currentState?.pushNamed('/chat', arguments: data);
        }
      });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool willExit = await showExitPopup(context);
        return willExit;
      },
      child: child,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request notification permissions
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications init
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings,
      onDidReceiveNotificationResponse: (payload) {
        // Handle tap on notification
        final data = payload?.payload;
        if (data != null && navigatorKey.currentState != null) {
          navigatorKey.currentState?.pushNamed('/chat', arguments: data);
        }
      });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (_currentOpenChatId != message.data['chatId']){

        showLocalNotification(
          message.notification?.title ?? "New Message",
          message.notification?.body ?? "",
        );
      }
    });

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (_currentOpenChatId != message.data['chatId']){

        showLocalNotification(
          message.notification?.title ?? "New Message",
          message.notification?.body ?? "",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final phone = message.data['phone'];
      if (phone != null && navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamed('/chat', arguments: phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routes: {
        '/chat': (context) => const HomeScreen(), // Replace with actual chat screen
      },
      home: const ExitWrapper(child: SplashScreen()),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const ExitWrapper(child: HomeScreen());
        }

        return const ExitWrapper(child: LoginScreen());
      },
    );
  }
}

/// Call these functions in your chat screen:
void setCurrentOpenChat(String phone) {
  _currentOpenChatId = phone;
}

void clearCurrentOpenChat() {
  _currentOpenChatId = null;
}


//pranjal
