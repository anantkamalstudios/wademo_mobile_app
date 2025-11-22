import 'package:flutter/material.dart';
import 'LoginScreen.dart'; // <-- changed import
// Removed HomeScreen.dart import since not needed

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _companyController = TextEditingController();
  String? _selectedSize;
  String? _selectedIndustry;

  final List<String> _industries = [
    'Technology',
    'Education',
    'Finance',
    'Healthcare',
    'Retail',
    'Manufacturing',
    'Other',
  ];

  void _goToLogin() {
    if (_companyController.text.isEmpty ||
        _selectedSize == null ||
        _selectedIndustry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), // <-- changed target
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Tell us a bit about your company",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please fill in the following details to help us customize your experience.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Company Name Field
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: "Company Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Company Size",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("1-10 Employees"),
                    value: "1-10 Employees",
                    groupValue: _selectedSize,
                    onChanged: (value) =>
                        setState(() => _selectedSize = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("10-50 Employees"),
                    value: "10-50 Employees",
                    groupValue: _selectedSize,
                    onChanged: (value) =>
                        setState(() => _selectedSize = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("200+ Employees"),
                    value: "200+ Employees",
                    groupValue: _selectedSize,
                    onChanged: (value) =>
                        setState(() => _selectedSize = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Select an Industry",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: const Text("Select Industry"),
              items: _industries
                  .map((industry) => DropdownMenuItem(
                value: industry,
                child: Text(industry),
              ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedIndustry = value),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _goToLogin, // <-- changed function
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
