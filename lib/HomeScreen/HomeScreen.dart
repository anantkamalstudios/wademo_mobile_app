import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Provider/HomeProvider.dart';
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
  final FirebaseAuth auth = FirebaseAuth.instance;

  late User? user;
  late String displayName;

  int _currentIndex = 0;
  bool _isChatOpen = false;
  static const cardShadow = Color(0x22000000);
  @override
  void initState() {
    super.initState();

    user = auth.currentUser;
    displayName = user?.displayName ?? "User";

    // Load API Data via Provider
    final hp = Provider.of<HomeProvider>(context, listen: false);
    hp.fetchContacts();
    hp.fetchCampaigns();
  }

  void _handleChatState(bool isOpen) {
    setState(() => _isChatOpen = isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HomeProvider>(context);

    final pages = [
      _buildHomePage(context, hp),
      ChatScreen(
        onChatStateChange: _handleChatState,
        onChatCountChange: hp.updateChatCount,
      ),
      const CampaignScreen(),
      ContactsScreen(
        onContactCountChange: (count) => hp.fetchContacts(),
      ),
      const SettingsScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ),

        bottomNavigationBar: _isChatOpen
            ? null
            : BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF004D40),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          // onTap: (index) => setState(() => _currentIndex = index),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (index == 1) {
                  hp.fetchChatsOnce();   // 👈 only fetch once per open
                }
              });
            },

            items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: "Home"),

            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (hp.totalChats > 0)
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.green,
                        child: Text(
                          hp.totalChats.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "Chats",
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
    );
  }

  // -------------------------------- UI -----------------------------------

  Widget _buildHomePage(BuildContext context, HomeProvider hp) {
    return RefreshIndicator(
      onRefresh: hp.refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // HEADER UI (same as your existing)
            _buildHeader(),

            const SizedBox(height: 16),

            _buildStats(hp),

            const SizedBox(height: 16),

            _buildRecentCampaigns(hp),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF063D2B),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome,\n$displayName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      color: Color(0xFF063D2B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATS
  Widget _buildStats(HomeProvider hp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "All Chats",
                  value: hp.totalChats.toString(),
                  sub: "184.62% Open rate",
                  icon: Icons.chat_bubble_outline,
                  bgIcon: Color(0xFFEFF9F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: "Templates",
                  value: "23",
                  sub: "23 Approved",
                  icon: Icons.folder_open,
                  bgIcon: Color(0xFFEAF6F0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Contact",
                  value: hp.totalContacts.toString(),
                  sub: "1 new this month",
                  icon: Icons.contact_page,
                  bgIcon: Color(0xFFEAF6F0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: "Campaigns",
                  value: hp.totalCampaigns.toString(),
                  sub: "92.5% Read rate",
                  icon: Icons.send,
                  bgIcon: Color(0xFFEAF6F0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // RECENT CAMPAIGNS
  Widget _buildRecentCampaigns(HomeProvider hp) {
    return _CardContainer(
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

          if (hp.recentCampaigns.isEmpty)
            const Text(
              "No Recent Campaigns",
              style: TextStyle(color: Colors.black54),
            ),

          ...hp.recentCampaigns.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFEFF9F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send, color: Color(0xFF0B5D3A)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["name"] ?? "No Name",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        item["is_active"] == 1 ? "Active" : "Inactive",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
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
        boxShadow: [
          BoxShadow(
               color: _HomeScreenState.cardShadow,
              blurRadius: 10)
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
        boxShadow:  [
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


