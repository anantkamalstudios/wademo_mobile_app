import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ContactsScreen extends StatefulWidget {
  final Function(int)? onContactCountChange;
  const ContactsScreen({Key? key, this.onContactCountChange}) : super(key: key);

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}


class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> contacts = [];

  bool selectionMode = false;
  Set<int> selectedIndexes = {};

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? selectedContact;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      setState(() {
        errorMessage = "Token not found. Please login again.";
        isLoading = false;
      });
      return;
    }

    final url = "https://www.anantkamalwademo.online/api/wpbox/getContacts?token=$token";

    print("📡 Calling API: $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("📥 API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("📦 API Raw Data: $decoded");

        final List<dynamic> data = decoded["contacts"] ?? [];

        contacts = data.map((item) {
          final fullName = ((item["name"] ?? "") + " " + (item["lastname"] ?? "")).trim();

          // Extract group name
          String groupName = "No Group";
          if (item["groups"] != null && item["groups"].isNotEmpty) {
            groupName = item["groups"][0]["name"] ?? "No Group";
          }

          return {
            "name": fullName.isEmpty ? "No Name" : fullName,
            "phone": item["phone"]?.toString() ?? "",
            "group": groupName,  // 🔥 SAVE GROUP HERE
          };
        }).toList();

        if (widget.onContactCountChange != null) {
          widget.onContactCountChange!(contacts.length);
        }

        print("📌 Parsed Contact Count: ${contacts.length}");

        setState(() => isLoading = false);
      } else {
        setState(() {
          errorMessage = "Server error ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ API error: $e");
      setState(() {
        errorMessage = "Failed to fetch data";
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.arrow_back),
                SizedBox(width: 10),
                Text("Contacts",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 20),

            _rowStats(),

            const SizedBox(height: 20),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
           : selectedContact != null
                ? _buildContactDetailCard()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactsActions(),
                const SizedBox(height: 20),

                _searchBar(),   // 👈 Add this

                const SizedBox(height: 20),
                _buildContactsList(),

              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search contacts...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
    );
  }


  Widget _buildContactsList() {
    final filteredContacts = contacts.where((c) {
      final name = c["name"].toLowerCase();
      final phone = c["phone"].toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          phone.contains(searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];

        return GestureDetector(
          onLongPress: () {
            setState(() {
              selectionMode = true;
              selectedIndexes.add(index);
            });
          },

          onTap: () {
            if (selectionMode) {
              setState(() {
                if (selectedIndexes.contains(index)) {
                  selectedIndexes.remove(index);
                  if (selectedIndexes.isEmpty) selectionMode = false;
                } else {
                  selectedIndexes.add(index);
                }
              });
            } else {
              setState(() {
                selectedContact = contact;
              });
            }
          },

          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                selectionMode
                    ? Checkbox(
                  value: selectedIndexes.contains(index),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedIndexes.add(index);
                      } else {
                        selectedIndexes.remove(index);
                        if (selectedIndexes.isEmpty) {
                          selectionMode = false;
                        }
                      }
                    });
                  },
                )
                    : const SizedBox(width: 0),

                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),

                // FIX OVERFLOW HERE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact["name"],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        contact["phone"],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          ),
        );
      },
    );
  }


  Widget _buildContactDetailCard() {
    final contact = selectedContact!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// BACK BUTTON
          GestureDetector(
            onTap: () {
              setState(() {
                selectedContact = null;
              });
            },
            child: const Icon(Icons.arrow_back),
          ),

          const SizedBox(height: 16),

          /// PROFILE HEADER
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact["name"] ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    contact["phone"] ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          /// DETAILS
          _detailRow("User", contact["name"]),
          _detailTag(
            "Groups",
            contact["group"] ?? "No Group",
            Colors.green.shade100,
            Colors.green,
          ),

          _detailRow("Last Updated", "2024-06-24 10:45:00"), // Replace with API field
          _detailRow("Phone", contact["phone"]),
          _detailTag(
            "Status",
            "Subscribed", // Replace with API
            Colors.green.shade100,
            Colors.green,
          ),

          const SizedBox(height: 25),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9FFF2),
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text("Chat"),
                  onPressed: () {},
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_off, color: Colors.redAccent)),

              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: Colors.green)),

              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value ?? "",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _detailTag(String title, String value, Color bg, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(value,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }


  Widget _buildContactsActions() {
    return Row(
      children: [
        Text("Contacts (${contacts.length})",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),

        const Spacer(),

        _actionButton(Icons.filter_alt, Colors.green.shade100),
        const SizedBox(width: 8),

        _actionButton(Icons.upload, Colors.green.shade100),
        const SizedBox(width: 8),

        _actionButton(Icons.refresh, Colors.red.shade100),
        const SizedBox(width: 8),

        _actionButton(Icons.add, Colors.green.shade700, isCircle: true, onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );

          // If contact was added, refetch contacts
          if (result == true) {
            fetchContacts();
          }
        }),





      ],
    );
  }

  Widget _actionButton(IconData icon, Color bgColor, {bool isCircle = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCircle ? 40 : 35,
        height: 35,
        decoration: BoxDecoration(
          color: bgColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }


  Widget _rowStats() {
    return Column(
      children: [
        Row(
          children: [
            _statBox("${contacts.length}", "Total Contacts", Colors.green),
            _statBox("${contacts.where((c) => c['subscribed'] == true).length}", "Subscribed", Colors.teal),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statBox("${contacts.where((c) => c['subscribed'] == false).length}", "Unsubscribed", Colors.redAccent),
            _statBox("${contacts.take(4).length}", "Added This Week", Colors.green), // You can modify logic for "Added This Week"
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ],
    );
  }


  Widget _statBox(String value, String label, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 5)
          ]),
      child: Column(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.people, color: color)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

}


class AddContactScreen extends StatefulWidget {
  const AddContactScreen({Key? key}) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {

  List<dynamic> groups = [];
  bool groupLoading = false;

  String? selectedGroup;





  TextEditingController nameCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController locationCtrl = TextEditingController();
  TextEditingController customCtrl = TextEditingController();

  String selectedCountry = "India";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }


  // ---------------------------
  // GET TOKEN FROM STORAGE
  // ---------------------------
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token"); // token NOT static
  }


  Future<void> fetchGroups() async {
    setState(() => groupLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing! Login again.")),
      );
      return;
    }

    final url = "https://www.anantkamalwademo.online/api/wpbox/getGroups?token=$token&showContacts=no";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          groups = decoded["groups"] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching groups: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("API Error: $e")),
      );
    }

    setState(() => groupLoading = false);
  }

  Future<void> createContact() async {
    print("Create contact called");

    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      print("Name or phone is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name & Phone required")),
      );
      return;
    }

    setState(() => loading = true);

    String? token = await getToken();
    print("Token: $token");

    if (token == null) {
      setState(() => loading = false);
      print("Token is null, cannot continue");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Login again.")),
      );
      return;
    }

    print("Selected Group: $selectedGroup");
    print("Name: ${nameCtrl.text}");
    print("Phone: ${phoneCtrl.text}");
    print("Email: ${emailCtrl.text}");
    print("Country: $selectedCountry");
    print("Location: ${locationCtrl.text}");
    print("Custom Field: ${customCtrl.text}");

    try {
      final response = await http.post(
        Uri.parse("https://www.anantkamalwademo.online/api/wpbox/makeContact?token=$token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameCtrl.text.trim(),
          "phone": phoneCtrl.text.trim(),
          "email": emailCtrl.text.trim(),
          "country": selectedCountry,
          "group": selectedGroup ?? "",
          "location": locationCtrl.text.trim(),
          "customField": customCtrl.text.trim(),
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        print("Contact added successfully");
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact Added Successfully ✓")),
        );
      } else {
        print("Error adding contact: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['message']}")),
        );



      }

    } catch (e) {
      print("Exception during createContact: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }


    setState(() => loading = false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Contact"),
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: loading ? null : createContact,
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Create Contact", style: TextStyle(fontSize: 18)),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    label: const SizedBox(),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),
            _inputField("Name", "Enter your name", controller: nameCtrl),
            _inputField("WhatsApp Number", "91*******", controller: phoneCtrl, keyboardType: TextInputType.number),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Groups", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),

                  groupLoading
                      ? const Center(child: CircularProgressIndicator())
                      :DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    hint: const Text("Select Group"),
                    value: selectedGroup,
                    items: groups.map((g) {
                      return DropdownMenuItem<String>(
                        value: g["name"]?.toString(),  // this can be null safely
                        child: Text(g["name"]?.toString() ?? ""),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedGroup = val); // val is String? so this is safe
                    },
                  ),



                  const SizedBox(height: 6),

                  // Button to refresh groups
                  TextButton(
                    onPressed: fetchGroups,
                    child: const Text("Load Groups"),
                  ),
                ],
              ),
            ),

            _dropdownField("Country", ["India", "USA", "UK"], (val) => setState(() => selectedCountry = val)),
            _inputField("Custom Field", "Custom info", controller: customCtrl),
            _inputField("Email", "Email address", controller: emailCtrl),
            _inputField("Location", "City or place", controller: locationCtrl),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint, {required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, Function(String) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => onChange(val!),
          ),
        ],
      ),
    );
  }
}

