import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginScreen.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomeScreen/HomeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController logoController;
  late Animation<double> logoMoveUp;

  late AnimationController imageController;
  late Animation<double> imageFadeIn;

  @override
  void initState() {
    super.initState();

    // Logo move up animation (longer duration)
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // move logo more upward
    logoMoveUp = Tween<double>(begin: 0, end: -160).animate(
      CurvedAnimation(parent: logoController, curve: Curves.easeOut),
    );

    // Image fade-in animation (slower)
    imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    imageFadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: imageController, curve: Curves.easeIn),
    );

    // Start animation sequence
    Future.delayed(const Duration(seconds: 1), () {
      logoController.forward();
    });

    Future.delayed(const Duration(seconds: 2), () {
      imageController.forward();
    });

    // Navigate after animation
    Timer(const Duration(seconds: 6), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      resizeToAvoidBottomInset: true, // important
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              FadeTransition(
                opacity: imageFadeIn,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Connecting Business via Whatsapp \nBusiness API",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Image.asset(
                        "assets/new_banner.png",
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 1.05,
                        height: MediaQuery.of(context).size.height * 0.55,
                      ),
                    ],
                  ),
                ),

              ),
              AnimatedBuilder(
                animation: logoController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, logoMoveUp.value),
                    child: child,
                  );
                },
                child: Center(
                  child: Image.asset(
                    "assets/white_logo.png",
                    height: 220,
                    width: 220,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    logoController.dispose();
    imageController.dispose();
    super.dispose();
  }

}
