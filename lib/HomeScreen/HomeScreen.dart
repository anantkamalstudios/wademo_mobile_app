import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
    fetchCampaignCount(); // fetch campaigns on load
  }

  void _handleChatState(bool isOpen) {
    setState(() => _isChatOpen = isOpen);
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_currentIndex],
      bottomNavigationBar: _isChatOpen
          ? null
          : BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF004D40),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        iconSize: 26, // same everywhere

        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
        ),

        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline),
                Positioned(
                  right: 0,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: const Text(
                      '6',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
            icon: Icon(Icons.campaign_outlined),
            label: "Campaigns",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            label: "Contacts",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),



    );
  }

  Future<void> fetchCampaignCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) return;

      final url =
          "https://anantkamalwademo.online/api/wpbox/getCampaigns?token=$token&type=api";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {

          final items = jsonResponse['items'];

          setState(() {
            totalCampaigns = items.length;

            /// take last 3 campaigns
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
                        "assets/banner.png",
                        height: 200,
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


                          const SizedBox(height: 6),
                          // const Text(
                          //   "No-code chatbots,\nAutomate responses to\n sales and support messages.",
                          //   style: TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 11,
                          //     height: 1.3,
                          //   ),
                          // ),
                          const SizedBox(height: 14),
                          Container(
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
                          child: _StatCard(
                            title: "All Chats",
                            value: totalChats.toString(),
                            sub: "184.62% Open rate",
                            icon: Icons.chat_bubble_outline,
                            bgIcon: softGreen,
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
                            value: totalContacts.toString(),
                            sub: "1 new this month",
                            icon: Icons.contact_page,
                            bgIcon: Color(0xFFEAF6F0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: "Campaigns",
                            value: totalCampaigns.toString(),
                            sub: "92.5% Read rate",
                            icon: Icons.send,
                            bgIcon: Color(0xFFEAF6F0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // _CardContainer(
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: const [
                    //               Text("Active subscription",
                    //                   style: TextStyle(
                    //                       fontWeight: FontWeight.w600)),
                    //               SizedBox(height: 6),
                    //               Text(
                    //                 "Your subscription expires on 2050-05-24 05:03:17",
                    //                 style: TextStyle(
                    //                     color: Colors.black54, fontSize: 13),
                    //               ),
                    //             ]),
                    //       ),
                    //       Container(
                    //         padding: const EdgeInsets.all(10),
                    //         decoration: BoxDecoration(
                    //           color: softGreen,
                    //           borderRadius: BorderRadius.circular(8),
                    //         ),
                    //         child:
                    //         const Icon(Icons.calendar_today, color: midGreen),
                    //       )
                    //     ],
                    //   ),
                    // ),
                    //
                    // const SizedBox(height: 12),

                    // _CardContainer(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       const Text("Campaign Performance",
                    //           style: TextStyle(fontWeight: FontWeight.w600)),
                    //       const SizedBox(height: 8),
                    //       const Text(
                    //         "Geographical distribution of your last campaign",
                    //         style: TextStyle(color: Colors.black54, fontSize: 13),
                    //       ),
                    //       const SizedBox(height: 14),
                    //       SizedBox(
                    //         width: double.infinity,
                    //         child: ElevatedButton(
                    //           onPressed: () {},
                    //           style: ElevatedButton.styleFrom(
                    //             backgroundColor: midGreen,
                    //             padding:
                    //             const EdgeInsets.symmetric(vertical: 14),
                    //             shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(8)),
                    //           ),
                    //           child: const Text(
                    //             "View Full Reports",
                    //             style: TextStyle(
                    //                 color: Colors.white,
                    //                 fontWeight: FontWeight.w600),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    const SizedBox(height: 16),

                    // _CardContainer(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: const [
                    //       Text("WhatsApp Business Details",
                    //           style: TextStyle(fontWeight: FontWeight.w600)),
                    //       SizedBox(height: 12),
                    //       Text("Anantkamal Studios",
                    //           style: TextStyle(fontWeight: FontWeight.w600)),
                    //       SizedBox(height: 6),
                    //       Text("Display Name Status: APPROVED",
                    //           style: TextStyle(color: Colors.black54)),
                    //       Text("WhatsApp Number: +91 76202 37235",
                    //           style: TextStyle(color: Colors.black54)),
                    //       Text("Quality Rating: GREEN",
                    //           style: TextStyle(color: Colors.black54)),
                    //       Text("Messaging Limit: TIER_1K",
                    //           style: TextStyle(color: Colors.black54)),
                    //       Text("Can Send Message: AVAILABLE",
                    //           style: TextStyle(color: Colors.black54)),
                    //       Text("Organization: Sachin k",
                    //           style: TextStyle(color: Colors.black54)),
                    //     ],
                    //   ),
                    // ),
                    //
                    // const SizedBox(height: 16),
                    _CardContainer(
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

                          // If empty → show simple message
                          if (recentCampaigns.isEmpty)
                            const Text(
                              "No Recent Campaigns",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),

                          // If not empty → show list items
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? "No Name",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['is_active'] == 1 ? "Active" : "Inactive",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),



                    const SizedBox(height: 30),
                  ],
                ),
              ),
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


