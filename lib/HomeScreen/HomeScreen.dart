import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';


import '../main.dart';
import 'CampaignScreen.dart';
import 'ChatsScreen.dart';
import 'ContactScreen.dart';
import 'SettingsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalChats = 0;
  int totalCampaigns = 0;
  int totalContacts = 0;


  List<dynamic> recentCampaigns = [];


  final FirebaseAuth auth = FirebaseAuth.instance;




// auth instance

  late User? user; // current logged-in user
  late String displayName; // user display name


  int _currentIndex = 0;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();

    user = auth.currentUser; // initialize user
    displayName = user?.displayName ?? "User"; // fallback
    fetchCampaignCount();
    fetchContactsCount();
    _loadProfileName();

  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString("name");

    if (savedName != null && savedName.trim().isNotEmpty) {
      setState(() {
        displayName = savedName;     // <-- override display name
      });
    }
  }



  Future<void> openDashboard() async {
    final Uri url = Uri.parse("https://anantkamalwademo.online/");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  void _handleChatState(bool isOpen) {
    setState(() => _isChatOpen = isOpen);
  }

  Future<void> fetchContactsCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = "https://anantkamalwademo.online/api/wpbox/getContacts?token=$token";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded["contacts"] ?? [];

        setState(() {
          totalContacts = data.length; // ✅ update count
        });
      }
    } catch (e) {
      print("Error fetching contacts: $e");
    }
  }


  static const darkGreen = Color(0xFF063D2B);
  static const midGreen = Color(0xFF0B5D3A);
  static const softGreen = Color(0xFFEFF9F1);
  static const cardShadow = Color(0x22000000);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(context),
      ChatScreen(
        onChatStateChange: _handleChatState,
        onChatCountChange: updateChatCount,
      ),
      const CampaignScreen(),
      ContactsScreen(
        onContactCountChange: updateContactCount,
      ),
      const SettingsScreen(),
    ];

    return ExitWrapper(
        child: WillPopScope(
            onWillPop: () => showExitPopup(context), // handle hardware back button
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                top: true,
                bottom: true, // ensures content doesn't go under gesture navigation
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),

              ),
      bottomNavigationBar: _isChatOpen
          ? null
          : SizedBox(
        // height: 65,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF004D40),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: "Home"),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),

                ],
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined), label: "Campaigns"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.contacts_outlined), label: "Contacts"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined), label: "Settings"),
          ],
        ),
      ),
            ),
        )
    );

  }


  Future<void> fetchCampaignCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) return;

      // FETCH **ALL CAMPAIGNS** (same as Campaign Screen)
      final url =
          "https://anantkamalwademo.online/api/wpbox/getCampaigns?token=$token";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final items = jsonResponse['items'];

          setState(() {
            totalCampaigns = items.length; // SAME as campaign screen

            // show last 3 campaigns
            recentCampaigns = items.take(3).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching campaigns: $e");
    }
  }



  void updateChatCount(int count) {
    setState(() => totalChats = count);
  }

  void updateContactCount(int count) {
    setState(() => totalContacts = count);
  }


  /// Pull-to-refresh function
  Future<void> refreshHomeData() async {
    await fetchCampaignCount();
    // Add any additional refresh logic here if needed
    setState(() {});
  }

  // ---------------- HOME PAGE UI -------------------
  Widget _buildHomePage(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshHomeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16), // safe space at the bottom
          child: Column(
            children: [
              // HEADER BANNER
              Container(
                width: double.infinity,
                height: 180,
                decoration: const BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: 0,
                      child: Image.asset(
                        "assets/new_banner.png",
                        height: 170,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome,\n$displayName",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: openDashboard,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Get Started",
                                style: TextStyle(
                                  color: darkGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = 1),
                        child: _StatCard(
                          title: "All Chats",
                          value: totalChats.toString(),
                          sub: "184.62% Open rate",
                          icon: Icons.chat_bubble_outline,
                          bgIcon: softGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        // onTap: () => setState(() => _currentIndex = 1),
                        child: _StatCard(
                          title: "Templates",
                          value: "23",
                          sub: "23 Approved",
                          icon: Icons.folder_open,
                          bgIcon: Color(0xFFEAF6F0),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = 3),
                        child: _StatCard(
                          title: "Contact",
                          value: totalContacts.toString(),
                          sub: "1 new this month",
                          icon: Icons.contact_page,
                          bgIcon: Color(0xFFEAF6F0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = 2),
                        child: _StatCard(
                          title: "Campaigns",
                          value: totalCampaigns.toString(),
                          sub: "92.5% Read rate",
                          icon: Icons.send,
                          bgIcon: Color(0xFFEAF6F0),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Recent Campaigns Card
                // Recent Campaigns Card
                InkWell(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: _CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Campaigns",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (recentCampaigns.isEmpty)
                          const Text(
                            "No Recent Campaigns",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),

                        ...recentCampaigns.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: softGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.send, color: midGreen),
                                ),
                                const SizedBox(width: 12),

                                // ✅ Wrap Column with Expanded to prevent overflow
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? "No Name",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['is_active'] == 1 ? "Active" : "Inactive",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 30),
              ],
            ),
          )

          ],
          ),
        ),
      ),
    );
  }

}

// ---------------- REUSABLE WIDGETS -------------------

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: _HomeScreenState.cardShadow, blurRadius: 10)
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color bgIcon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.bgIcon,
  });

  static const midGreen = Color(0xFF0B5D3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: _HomeScreenState.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 6),
                Text(sub,
                    style:
                    const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgIcon,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: midGreen),
          )
        ],
      ),
    );
  }
}


