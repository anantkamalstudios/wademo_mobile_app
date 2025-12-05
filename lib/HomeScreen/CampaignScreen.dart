import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  List<dynamic> campaigns = [];
  bool isLoading = true;

  // ▼▼ NEW TOGGLES ▼▼
  bool showAll = true; // default
  bool showApi = false;

  @override
  void initState() {
    super.initState();
    fetchCampaigns();
  }

  Future<void> fetchCampaigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) {
        print("Token missing");
        return;
      }

      // ▼▼ DYNAMIC URL BASED ON CHECKBOX ▼▼
      String url =
          "https://anantkamalwademo.online/api/wpbox/getCampaigns?token=$token";

      if (showApi) {
        url += "&type=api";
      }

      print("CALLING URL: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          setState(() {
            campaigns = jsonResponse['items'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching campaigns: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Campaigns",
          style: TextStyle(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        bottom: true, // ensures content doesn't overlap gesture bars
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchCampaigns,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                const Text(
                  "Campaign Performance",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    _metricBox(
                      value: campaigns.length.toString(),
                      label: "Total Campaigns",
                    ),
                    const SizedBox(width: 10),
                    _progressMetricBox(
                      value: "90",
                      label: "Messages Sent",
                      progressPercent: 0.24,
                      footer: "24.5% of total contacts",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _progressMetricBox(
                      value: "53.3%",
                      label: "Delivery Rate",
                      progressPercent: 0.53,
                      footer: "48 delivered  •  90 sent",
                    ),
                    const SizedBox(width: 10),
                    _progressMetricBox(
                      value: "93.8%",
                      label: "Read Rate",
                      progressPercent: 0.93,
                      footer: "45 read  •  0 clicks",
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _overviewSection(),
                const SizedBox(height: 20),

                // ▼ FILTER CHECKBOXES ▼
                Row(
                  children: [
                    Checkbox(
                      value: showAll,
                      onChanged: (val) {
                        setState(() {
                          showAll = true;
                          showApi = false;
                          isLoading = true;
                        });
                        fetchCampaigns();
                      },
                    ),
                    const Text("All Campaigns"),
                    const SizedBox(width: 20),
                    Checkbox(
                      value: showApi,
                      onChanged: (val) {
                        setState(() {
                          showApi = true;
                          showAll = false;
                          isLoading = true;
                        });
                        fetchCampaigns();
                      },
                    ),
                    const Text("API Campaigns"),
                  ],
                ),
                const SizedBox(height: 12),

                // ▼ Campaign List ▼
                campaigns.isEmpty
                    ? const Text("No Campaigns Found")
                    : ListView.builder(
                  itemCount: campaigns.length,
                  shrinkWrap: true, // fix for infinite height
                  physics:
                  const NeverScrollableScrollPhysics(), // scroll stays on parent
                  itemBuilder: (context, index) {
                    return _campaignItem(item: campaigns[index]);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// -------- METRIC CARDS ----------
  Widget _metricBox({required String value, required String label}) {
    return Expanded(
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _progressMetricBox({
    required String value,
    required String label,
    required String footer,
    required double progressPercent,
  }) {
    return Expanded(
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value,
                style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(footer,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration:
      _cardDecoration(color: const Color(0xFFF4F4F4), shadow: false),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _overviewTile(Icons.send, "Total Sent", "1"),
          _overviewTile(Icons.check_circle, "Delivered", "0"),
          _overviewTile(Icons.mark_email_read_outlined, "Read", "0"),
          _overviewTile(Icons.mouse, "Clicks", "0"),
        ],
      ),
    );
  }

  Widget _campaignItem({required Map<String, dynamic> item}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CampaignDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: _cardDecoration(shadow: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['name'] ?? "Unnamed",
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              "${item['is_active'] == 1 ? "Active" : "Inactive"} • Created ${item['created_at']?.substring(0, 10) ?? "Unknown"}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _badge("${item['total_contacts']} Contacts", Colors.green.shade100),
                const SizedBox(width: 8),
                Text("Sent: ${item['sent']}",
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  BoxDecoration _cardDecoration(
      {Color color = Colors.white, bool shadow = false}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: shadow ? null : Border.all(color: Colors.black12),
      boxShadow:
      shadow ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)] : [],
    );
  }

  Widget _badge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _overviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;

  const _overviewTile(this.icon, this.title, this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.green),
        const SizedBox(height: 4),
        Text(count,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}



class CampaignDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const CampaignDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final delivered = item['delivered_to'] ?? 0;
    final total = item['total_contacts'] ?? 1;
    final read = item['read_by'] ?? 0;
    final clicks =  item['used'] ?? 0;

    double deliveryRate = total == 0 ? 0 : delivered / total;
    double readRate = delivered == 0 ? 0 : read / delivered;
    double engagementRate = delivered == 0 ? 0 : clicks / delivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? "Campaign Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TITLE + STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['name'] ?? "",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item['is_active'] == 1
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['is_active'] == 1 ? "Completed" : "Inactive",
                    style: const TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // METRICS ROW (Three Cards)
            Row(
              children: [
                _metricCard(
                  title: "Delivery Rate",
                  percent: (deliveryRate * 100).toStringAsFixed(1),
                  valueText: "$delivered delivered • $total total",
                ),
                const SizedBox(width: 10),
                _metricCard(
                  title: "Read Rate",
                  percent: (readRate * 100).toStringAsFixed(1),
                  valueText: "$read read • $delivered delivered",
                ),
                const SizedBox(width: 10),
                _metricCard(
                  title: "Engagement",
                  percent: (engagementRate * 100).toStringAsFixed(1),
                  valueText: "$clicks clicks • $read read",
                ),
              ],
            ),

            const SizedBox(height: 20),

            // CONTACTS REACHED BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.toString(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  const Text("Contacts Reached"),
                  Text("${((total / 385) * 100).toStringAsFixed(2)}% of total contacts",
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TEMPLATE NAME BOX
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item['trigger'] ?? "",
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
      {required String title,
        required String percent,
        required String valueText}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              "$percent%",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            Text(valueText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}



