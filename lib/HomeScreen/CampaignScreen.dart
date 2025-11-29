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

  List<dynamic> recentCampaigns = [];


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

      final url =
          "https://anantkamalwademo.online/api/wpbox/getCampaigns?token=$token&type=api";

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
        title: const Text(
          "Campaigns",
          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Campaign Performance",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 14),

            /// ---- Top Performance Cards ----
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

            /// ---- Overview Box ----
            _overviewSection(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "All Campaigns",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ---- Dynamic Campaign List ----
            campaigns.isEmpty
                ? const Text("No Campaigns Found", style: TextStyle(color: Colors.grey))
                : Column(
              children: campaigns.map((item) {
                return _campaignItem(item: item);
              }).toList(),
            ),
          ],
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
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),

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
                Text(footer, style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
      decoration: _cardDecoration(color: const Color(0xFFF4F4F4)),
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
  Widget _campaignItem({
    required Map<String, dynamic> item,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailsScreen(campaign: item),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("${item['is_active'] == 1 ? "Active" : "Inactive"} • Created ${item['created_at']?.substring(0, 10) ?? "Unknown"}",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                _badge("${item['total_contacts']} Contacts", Colors.green.shade100),
                const SizedBox(width: 8),
                Text("Sent: ${item['sent']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }


  BoxDecoration _cardDecoration({Color color = Colors.white, bool shadow = false}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: shadow ? null : Border.all(color: Colors.black12),
      boxShadow: shadow ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)] : [],
    );
  }

  Widget _badge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
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
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}






class CampaignDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final createdDate = (campaign['created_at'] ?? "").toString().split("T").first;
    final media = campaign['media_link'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Campaigns detailed",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _campaignHeader(),

            const SizedBox(height: 20),

            // Dates Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$createdDate  Created", style: _boldGreyStyle()),
                Text("$createdDate  Last activity", style: _boldGreyStyle()),
              ],
            ),

            const SizedBox(height: 20),

            // Contacts box
            _statsCard(
              "${campaign['total_contacts'] ?? 0}",
              "Contacts Reached",
              "${((campaign['total_contacts'] ?? 0) / (campaign['total_contacts'] == 0 ? 1 : campaign['total_contacts']) * 100).toStringAsFixed(2)}% of total contacts",
            ),

            const SizedBox(height: 20),

            // 3 Statistic Cards
            Row(
              children: [
                Expanded(child: _metricCard(
                  title: "Delivery Rate",
                  delivered: campaign['delivered_to'],
                  total: campaign['total_contacts'],
                )),
                const SizedBox(width: 10),
                Expanded(child: _metricCard(
                  title: "Read Rate",
                  delivered: campaign['read_by'],
                  total: campaign['delivered_to'],
                )),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _metricCard(
                  title: "Engagement",
                  delivered: campaign['sent'],
                  total: campaign['read_by'],
                )),
              ],
            ),

            const SizedBox(height: 25),

            // Media Block

          ],
        ),
      ),
    );
  }

  // ---------------- UI WIDGETS ---------------- //

  Widget _campaignHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.send, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              campaign['name'] ?? "No Name",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              campaign['template_id'].toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.visibility, color: Colors.grey, size: 20)
        ],
      ),
    );
  }

  Widget _statsCard(String count, String title, String percent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFCF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 5),
          Text(percent, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _metricCard({required String title, required num delivered, required num total}) {
    final percent = total == 0 ? 0 : (delivered / total) * 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title),
          const SizedBox(height: 10),
          Text("$delivered delivered / $total total", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }


  TextStyle _boldGreyStyle() =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600);
}




