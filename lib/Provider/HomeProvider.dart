import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider extends ChangeNotifier {
  int totalChats = 0;
  int totalCampaigns = 0;
  int totalContacts = 0;

  List<dynamic> recentCampaigns = [];

  bool isLoading = false;

  bool _fetchedOnce = false;

  Future<void> fetchChatsOnce() async {
    if (_fetchedOnce) return;
    _fetchedOnce = true;
    // await _fetchConversationsAndPopulate();
  }


  // -------------------- LOAD ALL DATA --------------------
  Future<void> loadAllData() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchCampaigns(),
      fetchContacts(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  // -------------------- FETCH CONTACTS --------------------
  Future<void> fetchContacts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) return;

      final url =
          "https://anantkamalwademo.online/api/wpbox/getContacts?token=$token";

      final response = await http.get(Uri.parse(url));
      final decoded = jsonDecode(response.body);

      final List<dynamic> contacts = decoded["contacts"] ?? [];

      totalContacts = contacts.length;
      notifyListeners();
    } catch (e) {
      print("❌ Error fetching contacts: $e");
    }
  }

  // -------------------- FETCH CAMPAIGNS --------------------
  Future<void> fetchCampaigns() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      if (token.isEmpty) return;

      final url =
          "https://anantkamalwademo.online/api/wpbox/getCampaigns?token=$token";

      final response = await http.get(Uri.parse(url));
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse["status"] == "success") {
        final List items = jsonResponse["items"];

        totalCampaigns = items.length;
        recentCampaigns = items.take(3).toList();
      }

      notifyListeners();
    } catch (e) {
      print("❌ Error fetching campaigns: $e");
    }
  }

  // -------------------- CHAT COUNT (updated from chat screen) --------------------
  void updateChatCount(int count) {
    totalChats = count;
    notifyListeners();
  }
  // ------------ THIS WAS MISSING (Fixes your error) ----------
  Future<void> refreshAll() async {
    await fetchContacts();
    await fetchCampaigns();
    notifyListeners();
  }
}

