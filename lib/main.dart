import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'HomeScreen/HomeScreen.dart';
import 'Screens/LoginScreen.dart';
import 'Screens/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// 🚀 INTERNET CHECKER WRAPPER
class InternetChecker extends StatefulWidget {
  final Widget child;
  const InternetChecker({super.key, required this.child});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    // Delay until first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Connectivity().onConnectivityChanged.listen((result) {
        if (!mounted) return;

        if (result == ConnectivityResult.none) {
          _showNoInternetPopup();
        } else {
          if (isDialogOpen && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            isDialogOpen = false;
          }
        }
      });
    });
  }

  void _showNoInternetPopup() {
    if (isDialogOpen) return;
    isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text("No Internet Connection"),
        content: const Text("Please check your internet or WiFi."),
        actions: [
          TextButton(
            child: const Text("Retry"),
            onPressed: () async {
              var res = await Connectivity().checkConnectivity();
              if (res != ConnectivityResult.none && mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                isDialogOpen = false;
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// 🚀 MAIN APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InternetChecker(
      child: MaterialApp(
        title: 'New Test App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// 🚀 AUTH WRAPPER (Optional, if you want Firebase login state)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
