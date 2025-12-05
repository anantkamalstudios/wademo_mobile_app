import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;

  Map<String, int> _lastNotifiedMessageId = {};
  String? _currentOpenChatId;


  // Singleton init
  Future<void> init() async {
    // initialize flutter local notifications
    var androidInit = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInit = const DarwinInitializationSettings();
    var initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // load last notified map
    await _loadLastNotifiedMap();

    // start polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForNewMessages();
    });
  }

  void setCurrentOpenChat(String chatId) {
    _currentOpenChatId = chatId;
  }


  void clearCurrentOpenChat() {
    _currentOpenChatId = null;
  }

  Future<void> _loadLastNotifiedMap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('lastNotifiedMap');
    if (stored != null) {
      _lastNotifiedMessageId =
      Map<String, int>.from(jsonDecode(stored).map((k, v) => MapEntry(k, v as int)));
    }
  }

  Future<void> _saveLastNotifiedMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastNotifiedMap', jsonEncode(_lastNotifiedMessageId));
  }

  Future<void> _checkForNewMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse(
          "https://anantkamalwademo.online/api/wpbox/getConversations/none?mobile_api=true&page=1&per_page=50");
      final body = jsonEncode({"token": token});

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode != 200) return;

      final Map<String, dynamic> data = json.decode(resp.body);
      List<dynamic>? conversations;

      if (data.containsKey('conversations')) {
        conversations = data['conversations'];
      } else if (data.containsKey('contacts')) {
        conversations = data['contacts'];
      } else if (data.containsKey('data')) {
        conversations = data['data'];
      }

      if (conversations == null || conversations.isEmpty) return;

      for (var chat in conversations) {
        String chatId = (chat['id'] ?? chat['conversation_id'] ?? '').toString();
        int lastMsgId = int.tryParse(
            (chat['last_message_id'] ?? chat['last_message']?.hashCode ?? 0).toString()) ??
            0;
        String phone = (chat['phone'] ?? chat['msisdn'] ?? chat['number'] ?? '').toString();

        int lastNotifiedId = _lastNotifiedMessageId[chatId] ?? 0;

        // only notify if new message and not the currently open chat
        if (lastMsgId > lastNotifiedId && chatId != _currentOpenChatId)
        {
          String message = chat['last_message'] ??
              chat['last_message_text'] ??
              chat['last_sender_message'] ??
              '';
          String name = (chat['name'] ?? chat['contact_name'] ?? 'Unknown').toString();

          _showNotification(name, message);

          _lastNotifiedMessageId[chatId] = lastMsgId;
          await _saveLastNotifiedMap();
        }
      }
    } catch (e) {
      print("❌ NotificationService error: $e");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    var android = const AndroidNotificationDetails(
      'chat_channel',
      'Messages',
      importance: Importance.max,
      priority: Priority.high,
    );

    var ios = const DarwinNotificationDetails();

    var platform = NotificationDetails(android: android, iOS: ios);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platform,
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
