import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InternetChecker extends StatefulWidget {
  final Widget child;
  const InternetChecker({super.key, required this.child});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    /// Run after UI is ready → popup works correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Connectivity().onConnectivityChanged.listen((result) {
        if (result == ConnectivityResult.none) {
          _showNoInternetPopup();
        } else {
          if (isDialogOpen) {
            Navigator.of(context).pop();
            isDialogOpen = false;
          }
        }
      });
    });
  }

  void _showNoInternetPopup() {
    if (isDialogOpen) return;
    isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("No Internet Connection"),
        content: const Text("Please check your Internet or WiFi."),
        actions: [
          TextButton(
            child: const Text("Retry"),
            onPressed: () async {
              var res = await Connectivity().checkConnectivity();
              if (res != ConnectivityResult.none) {
                Navigator.of(context).pop();
                isDialogOpen = false;
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
