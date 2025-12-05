import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/authService.dart';
import 'ForgotPasswordScreen.dart';
import '../HomeScreen/HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();




  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;


  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");
  }
  // -------------------------------------------------------------------------
  //  🔹 ONLY ADDED PRINT STATEMENTS HERE
  // -------------------------------------------------------------------------
  Future<void> _signIn() async {
    setState(() => _loading = true);

    const String apiUrl = "https://anantkamalwademo.online/api/login";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setInt("id", data["id"]);
        await prefs.setString("name", data["name"]);
        await prefs.setString("email", data["email"]);
        await prefs.setString("app_logo", data["app_logo"] ?? "");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["errMsg"] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }


  Future<void> _signInWithGoogle() async {
    print("🔵 Google Sign-In Started");

    try {
      await _auth.signInWithGoogle();
      print("🟢 Google Sign-In Success");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      print("⛔ Google Sign-In Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }


  Future<void> _signInWithFacebook() async {
    print("🔵 Facebook Sign-In Started");

    try {
      await _auth.signInWithFacebook();
      print("🟢 Facebook Sign-In Success");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      print("⛔ Facebook Sign-In Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook sign-in failed: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 40),

            Image.asset(
              "assets/black_logo.png",
              height: 70,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            const Text(
              "Sign in or Create an account",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // ElevatedButton.icon(
            //   onPressed: _signInWithGoogle,
            //   icon: Image.asset(
            //     'assets/google.png',
            //     height: 24,
            //     width: 24,
            //   ),
            //   label: const Text("Sign in with Google"),
            //   style: ElevatedButton.styleFrom(
            //     foregroundColor: Colors.black87,
            //     backgroundColor: Colors.grey.shade200,
            //     minimumSize: const Size(double.infinity, 50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 12),

            // ElevatedButton.icon(
            //   onPressed: _signInWithFacebook,
            //   icon: Image.asset(
            //     'assets/facebook.png',
            //     height: 24,
            //     width: 24,
            //   ),
            //   label: const Text("Sign in with Facebook"),
            //   style: ElevatedButton.styleFrom(
            //     foregroundColor: Colors.black87,
            //     backgroundColor: Colors.grey.shade200,
            //     minimumSize: const Size(double.infinity, 50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),

            Row(
              children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Or"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),

            const SizedBox(height: 25),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    ),
                    const Text("Remember me"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password ?",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Sign In",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            // OutlinedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const SignUpScreen()),
            //     );
            //   },
            //   style: OutlinedButton.styleFrom(
            //     minimumSize: const Size(double.infinity, 50),
            //     side: BorderSide(color: Colors.grey.shade300),
            //   ),
            //   child: const Text("Create new account"),
            // ),
          ],
        ),
      ),
    );
  }
}
