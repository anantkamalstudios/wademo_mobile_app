import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== HEADER ======
            Container(
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ====== ACCOUNT ======
            _settingsSection(
              title: "Account",
              children: [
                _settingsItem(
                  "Profile",
                  Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),_settingsItem(
                  "Change Password",
                  Icons.lock_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
                    );
                  },
                ),

              ],
            ),

            // ====== BUSINESS ======
            _settingsSection(
              title: "Business",
              children: [
                _settingsItem("Business info", Icons.public),
                _settingsItem("API Key", Icons.vpn_key_outlined),
              ],
            ),

            // ====== SUBSCRIPTION ======
            _settingsSection(
              title: "Subscription",
              children: [],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CARD WITH TITLE
  Widget _settingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title inside card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ...children.isNotEmpty
              ? children
              : [
            const SizedBox(height: 45),
          ],
        ],
      ),
    );
  }

  // ✅ ROW ITEM
  Widget _settingsItem(String title, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController(text: "Sachin K");
  final _emailController = TextEditingController(text: "anantkamal@gmail.com");
  final _phoneController = TextEditingController(text: "9387373632");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                "Update your account's profile information and email address.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 20),

              // NAME
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // EMAIL
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // PHONE WITH COUNTRY CODE
              Row(
                children: [
                  Container(
                    height: 55,
                    width: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "+91",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.white, // ✅ text is white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      _msg("Passwords do not match");
      return;
    }

    try {
      setState(() => _loading = true);

      User? user = _auth.currentUser;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentCtrl.text.trim(),
      );

      // ✅ Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // ✅ Change password
      await user.updatePassword(_newCtrl.text.trim());

      _msg("Password updated successfully!");

      Navigator.pop(context);

    } catch (e) {
      _msg(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _msg(String txt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(txt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Ensure your account is using a long, random password to stay secure.",
            ),
            const SizedBox(height: 20),

            _field(
              controller: _currentCtrl,
              hint: "Current Password",
              show: _showOld,
              toggle: () => setState(() => _showOld = !_showOld),
            ),
            _field(
              controller: _newCtrl,
              hint: "Enter New Password",
              show: _showNew,
              toggle: () => setState(() => _showNew = !_showNew),
            ),
            _field(
              controller: _confirmCtrl,
              hint: "Confirm Password",
              show: _showConfirm,
              toggle: () => setState(() => _showConfirm = !_showConfirm),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green.shade800,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Proceed",
                style: TextStyle(color: Colors.white),   // ✅ set text color to white
              ),


            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: !show,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: InkWell(
            onTap: toggle,
            child: Icon(show ? Icons.visibility : Icons.visibility_off),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

