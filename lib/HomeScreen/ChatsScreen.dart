import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


import '../Services/NotificationService.dart';
import '../main.dart';


class ChatScreen extends StatefulWidget {
  final ValueChanged<bool> onChatStateChange;
  final ValueChanged<int> onChatCountChange;

  final bool openChatDirectly;
  final String? phone;
  final String? name;

  // 👈 NEW
  ChatScreen({

    Key? key,
    this.openChatDirectly = false,
    this.phone,
    this.name,
    required this.onChatStateChange,
    required this.onChatCountChange,
  }) : super(key: key);



  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isChatOpen = false;
  bool _showQuickOptions = false;
  bool _showAttachmentOptions = false;
  bool _isSearching = false; // search mode
  String _searchQuery = ""; // search text
  String? _selectedUser;
  String? _selectedPhone; // phone of the open chat (from API)
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedFile;
  Map<String, int> _lastNotifiedMessageId = {};

  Map<String,int> lastMessagePerChat = {};

  // In your State class
  Map<String, dynamic>? _replyingToMessage; // The message being replied to




  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _perPage = 20;
  bool _hasMore = true;

  List<XFile> _selectedImages = [];

  String? _previewImagePath;
  bool _showPreviewAppBar = true;

  Set<int> _selectedMessageIndexes = {};
  bool _isSelectionMode = false;


  Timer? _pollingTimer;
  String? _token;

  List<Map<String, dynamic>> _chats = [];

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];

  final TextEditingController _messageController = TextEditingController();


  @override
  void initState() {
    super.initState();

    if (widget.openChatDirectly) {
      NotificationService().setCurrentOpenChat(widget.phone ?? '');
    }

    var androidInit = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInit = const DarwinInitializationSettings();
    var initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    flutterLocalNotificationsPlugin.initialize(initSettings);


    _loadLastNotifiedMap(); // Load persisted notification map

    _pollingTimer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (!_isChatOpen) {
        await _fetchConversationsAndPopulate();
      }

      if (_isChatOpen && _selectedPhone != null) {
        final chat = _chats.firstWhere(
                (c) => c['phone'].toString() == _selectedPhone.toString(),
            orElse: () => {});

        if (chat.isNotEmpty) {
          await _fetchMessages(chat['id'].toString());
        }
      }
    });



    if (widget.openChatDirectly) {
      _isChatOpen = true;
      _selectedPhone = widget.phone;
      _selectedUser = widget.name;
      _fetchMessages(widget.phone!);
    }
    _loadTokenAndFetchChats();
  }

  @override
  void dispose() {
    NotificationService().clearCurrentOpenChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredChats = _chats
        .where((chat) => chat['name']
        .toString()
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
        .toList();

    filteredChats.sort((a, b) {
      DateTime aTime = DateTime.tryParse(a['time'] ?? '') ?? DateTime(1970);
      DateTime bTime = DateTime.tryParse(b['time'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime); // latest first
    });

    return ExitWrapper(
      child: WillPopScope(
        onWillPop: () => showExitPopup(context),

        // ❌ Removed SafeArea from here (CAUSE OF CRASH)

        child: Scaffold(
          backgroundColor: Colors.white,

          appBar: _previewImagePath != null
              ? null
              : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleSpacing: 0,

            title: _isChatOpen
                ? _chatAppBar()
                : _isSearching
                ? _buildSearchField()
                : const Text(
              'Chats',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            actions: _isChatOpen
                ? [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.teal),
                onPressed: () {},
              ),
            ]
                : [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black54),
                  onPressed: () {
                    setState(() => _isSearching = true);
                  },
                ),

              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = "";
                    });
                  },
                ),

              IconButton(
                icon:
                const Icon(Icons.more_vert, color: Colors.black54),
                onPressed: () {},
              ),
            ],

            leading: _isChatOpen
                ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.teal),
              onPressed: () {
                setState(() {
                  _isChatOpen = false;
                  _showQuickOptions = false;
                  _showAttachmentOptions = false;
                  _selectedImage = null;
                  _selectedFile = null;
                  _selectedPhone = null;
                });
                widget.onChatStateChange?.call(false);
              },
            )
                : _isSearching
                ? IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.black54),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = "";
                });
              },
            )
                : null,
          ),

          // ✅ SafeArea moved INSIDE Scaffold
          body: SafeArea(
            top: true,
            bottom: true,
            child: _isChatOpen ? _chatView() : _chatListView(filteredChats),
          ),
        ),
      ),
    );
  }


  Future<void> showNotification(String name, String message) async {
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
      name,
      message,
      platform,
    );
  }


  Future<void> _loadCachedMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString("cached_$chatId");

    if (cached != null) {
      List decoded = jsonDecode(cached);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }


  Widget _chatListView(List<Map<String, dynamic>> chats) {
    if (chats.isEmpty) {
      return const Center(
        child: Text(
          "No chats found",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: true,
      child: RefreshIndicator(
        onRefresh: _refreshChats,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!_isLoadingMore &&
                _hasMore &&
                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
              _fetchConversationsAndPopulate(loadMore: true);
            }
            return false;
          },
          child: ListView.separated(
            itemCount: chats.length, // ✅ removed +1 for loader
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                onTap: () async {
                  String chatId = chat['id'].toString();

                  setState(() {
                    _isChatOpen = true;
                    _selectedUser = chat['name'];
                    _selectedPhone = chat['phone'].toString();
                  });

                  // Show cached messages instantly
                  await _loadCachedMessages(chatId);

                  // Fetch new messages in background
                  Future.microtask(() async {
                    await _fetchMessages(chatId);
                  });
                },

                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: FutureBuilder<String?>(
                    future: _getSavedAvatar(chat['name']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final savedAvatar = snapshot.data;
                      final avatarToShow = savedAvatar ?? chat['avatar'] ?? '';

                      if (avatarToShow.isNotEmpty) {
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: avatarToShow.startsWith('http')
                              ? NetworkImage(avatarToShow)
                              : FileImage(File(avatarToShow)) as ImageProvider,
                        );
                      }

                      // Safe initials calculation
                      String initials = "?";
                      if (chat['name'] != null && chat['name'].toString().trim().isNotEmpty) {
                        final names = chat['name']
                            .toString()
                            .trim()
                            .split(" ")
                            .where((e) => e.isNotEmpty)
                            .toList();
                        if (names.isNotEmpty) {
                          initials = names.length == 1
                              ? names[0][0].toUpperCase()
                              : names[0][0].toUpperCase() +
                              (names.length > 1 ? names[1][0].toUpperCase() : "");
                        }
                      }

                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.teal,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                title: Text(
                  chat['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.done_all, size: 14, color: Colors.teal),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        chat['message'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(chat['time'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    if ((chat['unread'] ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chat['unread']}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Future<void> sendMessage({bool isButton = false}) async {
    print("🔹 sendMessage called");

    if (_selectedPhone == null) {
      print("❌ No phone selected");
      return;
    }

    String text = _messageController.text.trim();
    if (text.isEmpty && !isButton) {
      print("❌ Message text empty");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) {
      print("❌ No token saved in SharedPreferences");
      return;
    }

    final uri = Uri.parse("https://anantkamalwademo.online/api/wpbox/sendmessage");
    print("🌐 API URL => $uri");

    final Map<String, Object> body = {
      "token": token,
      "phone": _selectedPhone!.trim(),
      "message": text,
    };

    print("📤 Request body => $body");

    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("📥 Response status => ${res.statusCode}");
      print("📥 Raw Response => ${res.body}");

      final decoded = jsonDecode(res.body);

      if (decoded["status"] == "success") {
        print("✅ API success");

        // Add message locally with proper DateTime
        setState(() {
          _messages.add({
            "text": text,
            "isMe": true,
            "time": DateTime.now().toIso8601String(), // store ISO string
            "wamid": decoded["message_wamid"],
          });
        });

        _messageController.clear();

        // Scroll to bottom after sending
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        print("❌ API returned failure => ${decoded["message"]}");
      }
    } catch (e) {
      print("❌ Catch exception: $e");
    }
  }

  Future<void> _fetchMessages(String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse("https://anantkamalwademo.online/api/wpbox/getMessages");
      final body = jsonEncode({
        "token": token,
        "contact_id": int.tryParse(contactId) ?? 0,
      });

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode != 200) return;

      // ✔ Decode JSON IN BACKGROUND thread
      final responseData = await compute(jsonDecode, resp.body);

      if (!responseData.containsKey("data")) return;

      List<dynamic> list = responseData["data"];
      List<Map<String, dynamic>> loadedMessages = [];

      String chatKey = "chat_$contactId";
      int lastNotifiedId = _lastNotifiedMessageId[chatKey] ?? 0;
      int highestMsgIdThisFetch = lastNotifiedId;

      for (var m in list) {
        bool isMe = m["is_message_by_contact"] == 0;
        int msgId = m["id"] ?? 0;

        // 🔔 Notification only when chat is closed
        if (!isMe && msgId > lastNotifiedId && contactId != _selectedPhone) {
          await showNotification(_selectedUser ?? "New Message", m["value"] ?? "");
        }

        if (msgId > highestMsgIdThisFetch) highestMsgIdThisFetch = msgId;

        loadedMessages.add({
          "type": m["header_image"] != "" ? "image" : "text",
          "text": m["value"] ?? "",
          "imageUrl": m["header_image"],
          "isMe": isMe,
          "time": m["created_at"]?.toString().substring(11, 16) ?? "",
        });
      }

      _lastNotifiedMessageId[chatKey] = highestMsgIdThisFetch;
      await _saveLastNotifiedMap();

      if (mounted) {
        setState(() {
          _messages = loadedMessages;
        });
      }

    } catch (e) {
      print("❌ _fetchMessages error: $e");
    }
  }

  Future<void> sendImage(File file) async {
    setState(() {
      _messages.insert(0, {
        "type": "image",
        "image": file.path,
        "isMe": true,
        "time": DateTime.now().toString().substring(11,16),
        "sending": true,
        "failed": false,
      });
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://anantkamalwademo.online/api/wpbox/sendmessage"),
    );

    request.fields['token'] = token;
    request.fields['phone'] = _selectedPhone ?? '';
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    try {
      var response = await request.send();
      String res = await response.stream.bytesToString();
      var decoded = jsonDecode(res);

      int index = _messages.indexWhere((m) => m["image"] == file.path && m["sending"] == true);

      if (decoded["status"] == "success") {
        setState(() {
          if (index != -1) {
            _messages[index]["sending"] = false;
            _messages[index]["wamid"] = decoded["message_wamid"]; // optional
          }
          _selectedImage = null;
        });
      } else {
        setState(() {
          if (index != -1) {
            _messages[index]["sending"] = false;
            _messages[index]["failed"] = true;
          }
        });
      }
    } catch (e) {
      print("❌ sendImage error: $e");
      int index = _messages.indexWhere((m) => m["image"] == file.path && m["sending"] == true);
      if (index != -1) {
        setState(() {
          _messages[index]["sending"] = false;
          _messages[index]["failed"] = true;
        });
      }
    }
  }


  Future<void> _fetchConversationsAndPopulate({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;
    if (!mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse(
          "https://anantkamalwademo.online/api/wpbox/getConversations/none?mobile_api=true&page=$_currentPage&per_page=$_perPage");

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"token": token}),
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

      if (conversations == null || conversations.isEmpty) {
        if (!mounted) return;
        setState(() => _hasMore = false);
        return;
      }

      // ✅ Only existing chats
      final List<Map<String, dynamic>> fetched = conversations
          .where((c) =>
      c['last_message'] != null ||
          c['last_message_text'] != null ||
          c['last_sender_message'] != null)
          .map((c) => {
        'id': (c['id'] ?? c['conversation_id'] ?? '').toString(),
        'name': (c['name'] ??
            (c['title'] ?? c['contact_name'] ?? 'Unknown'))
            .toString(),
        'message': _extractMessage(
            c['last_message'] ??
                c['last_message_text'] ??
                c['last_sender_message'] ??
                c['last_message_data'] ??
                ""),
        'last_message_id': int.tryParse(c['last_message_id']?.toString() ?? '') ??
            DateTime.tryParse(c['last_reply_at'] ?? '')?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'time': (c['last_reply_at'] ??
            c['updated_at'] ??
            c['last_message_time'] ??
            '')
            .toString(),
        'unread': c['unread'] ?? c['unread_count'] ?? 0,
        'avatar': (c['avatar'] ?? ''),
        'phone': (c['phone'] ?? c['msisdn'] ?? c['number'] ?? '')
            .toString()
            .trim(),
        'raw': c,
      })
          .toList();

      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _chats.addAll(fetched);
        } else {
          _chats = fetched;
        }

        // Sort by latest message
        _chats.sort((a, b) {
          DateTime aTime = DateTime.tryParse(a['time'] ?? '') ?? DateTime(1970);
          DateTime bTime = DateTime.tryParse(b['time'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        _isLoadingMore = false;
        _currentPage++;
      });

      if (mounted) widget.onChatCountChange(_chats.length);
    } catch (e) {
      print("❌ FETCH CONVERSATIONS ERROR: $e");
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }



  void _openChat(Map<String, dynamic> chat) {
    setState(() {
      _isChatOpen = true;
      _selectedUser = chat['name'];
      _selectedPhone = chat['phone'];
    });
    _loadCachedMessages(chat['id']);
    Future.microtask(() => _fetchMessages(chat['id']));
  }



  Future<void> _saveLastNotifiedMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastNotifiedMap', jsonEncode(_lastNotifiedMessageId));
  }

  Future<void> _loadLastNotifiedMap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('lastNotifiedMap');
    if (stored != null) {
      _lastNotifiedMessageId = Map<String, int>.from(
        jsonDecode(stored).map((k, v) => MapEntry(k, v as int)),
      );
    }
  }

  String _extractMessage(dynamic msg) {
    if (msg == null) return '';
    if (msg is String) return msg;
    if (msg is Map) {
      if (msg.containsKey("message")) return msg["message"].toString();
      if (msg.containsKey("content")) return msg["content"].toString();
      if (msg.containsKey("text")) return msg["text"].toString();
    }
    return msg.toString();
  }

  Future<void> _refreshChats() async {
    _currentPage = 1; // reset pagination
    _hasMore = true;

    if (!mounted) return;

    // Clear old chats to avoid duplicates temporarily showing
    setState(() {
      _chats = [];
    });

    // Fetch chats from API (will replace _chats because loadMore = false)
    await _fetchConversationsAndPopulate(loadMore: false);

    // Optionally, refresh current chat messages
    if (_isChatOpen && _selectedPhone != null) {
      final chat = _chats.firstWhere(
            (c) => c['phone'].toString() == _selectedPhone.toString(),
        orElse: () => {},
      );
      if (chat.isNotEmpty) {
        await _fetchMessages(chat['id'].toString());
      }
    }

    // Update chat count
    widget.onChatCountChange(_chats.length);
  }

  Widget _chatView() {
    return ExitWrapper(   // 🟢 WRAP HERE
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Chat messages
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/img.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          bool isMe = msg['isMe'] == true;

                          if (msg["type"] == "image") {
                            final networkUrl = msg["imageUrl"];
                            final localPath = msg["image"];
                            final time = msg["time"] ?? DateTime.now().toString().substring(11, 16);

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: () {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedMessageIndexes.add(index);
                                  });
                                },
                                onTap: () {
                                  if (_isSelectionMode) {
                                    setState(() {
                                      if (_selectedMessageIndexes.contains(index)) {
                                        _selectedMessageIndexes.remove(index);
                                        if (_selectedMessageIndexes.isEmpty) _isSelectionMode = false;
                                      } else {
                                        _selectedMessageIndexes.add(index);
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      _previewImagePath = localPath ?? networkUrl;
                                      _showPreviewAppBar = true;
                                    });
                                  }
                                },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            boxShadow: _selectedMessageIndexes.contains(index)
                                                ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)]
                                                : null,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: localPath != null
                                                ? Image.file(
                                              File(localPath),
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            )
                                                : Image.network(
                                              networkUrl ?? "https://via.placeholder.com/200",
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 4),

                                      Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(3.1416)
                                          ..rotateZ(0.1),
                                        child: IconButton(
                                          icon: Icon(Icons.reply_all, color: Colors.white, size: 22),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  )

                              ),
                            );

                          }



                          // Existing text message rendering
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedMessageIndexes.add(index);
                                });
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (_selectedMessageIndexes.contains(index)) {
                                      _selectedMessageIndexes.remove(index);
                                      if (_selectedMessageIndexes.isEmpty) _isSelectionMode = false;
                                    } else {
                                      _selectedMessageIndexes.add(index);
                                    }
                                  });
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.fromLTRB(14, 10, 50, 18), // extra padding for time
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.green.shade400
                                          : Colors.white.withOpacity(0.98),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                      ),
                                      boxShadow: _selectedMessageIndexes.contains(index)
                                          ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)]
                                          : null,
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                  // Timestamp inside bubble
                                  Positioned(
                                    bottom: 4,
                                    right: 8,
                                    child: Text(
                                      msg['time'] ?? DateTime.now().toString().substring(11, 16), // HH:mm
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : Colors.black54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),


                            ),
                          );

                        },
                      ),
                    ),


                    if (_selectedImage != null || _selectedFile != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _selectedImage != null
                              ? '📸 Image selected'
                              : _selectedFile != null
                              ? '📄 File selected'
                              : '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    if (_previewImagePath == null) _chatInput(),

                  ],
                ),
              ),

              // Attachment popup
              if (_showAttachmentOptions)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Material(
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _popupButton(Icons.image_outlined, "Image",
                                onTap: _openImagePickerDialog),
                            _popupButton(Icons.picture_as_pdf_outlined, "File",
                                onTap: _pickFile),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_previewImagePath != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPreviewAppBar = !_showPreviewAppBar;
                      });
                    },
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        children: [

                          /// Main preview image
                          Center(
                            child: InteractiveViewer(
                              child: _previewImagePath!.startsWith("http")
                                  ? Image.network(_previewImagePath!)
                                  : Image.file(File(_previewImagePath!)),
                            ),
                          ),

                          /// TOP OVERLAY (WhatsApp style)
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 200),
                            top: _showPreviewAppBar ? 0 : -80,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              child: Container(
                                height: 80,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                color: Colors.black54,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          color: Colors.white, size: 26),
                                      onPressed: () {
                                        setState(() {
                                          _previewImagePath = null;
                                        });
                                      },
                                    ),
                                    Row(
                                      children: [
                                        Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(3.1416)        // flip horizontally
                                            ..rotateZ(0.1),          // tilt to the right
                                          child: Icon(
                                            Icons.reply_all,
                                            color: Colors.white,
                                            size: 23,
                                          ),
                                        ),




                                        SizedBox(width: 10),
                                        Icon(Icons.more_vert,
                                            color: Colors.white, size: 26),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// BOTTOM REPLY BAR
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 200),
                            bottom: _showPreviewAppBar ? 0 : -100,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              child: Container(
                                height: 60,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                color: Colors.black54,
                                child: Row(
                                  children: [
                                    Icon(Icons.reply, color: Colors.white, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      "Reply",
                                      style:
                                      TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // After the full-screen image preview and quick options popup
              if (_isSelectionMode)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedMessageIndexes.toList().sort((b, a) => a.compareTo(b));
                              for (var i in _selectedMessageIndexes) {
                                _messages.removeAt(i);
                              }
                              _selectedMessageIndexes.clear();
                              _isSelectionMode = false;
                            });
                          },
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.reply_all, color: Colors.white),
                          onPressed: () {
                            print("Forward selected messages");
                          },
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedMessageIndexes.clear();
                              _isSelectionMode = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showQuickOptions)
                Positioned.fill(
                  child: _quickOptionsPopup(),
                ),
            ],
          ),
        ));

  }

  Widget _chatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          // Quick options button
          // IconButton(
          //   icon: const Icon(Icons.bolt_outlined, color: Colors.amber, size: 28),
          //   onPressed: () {
          //     setState(() {
          //       _showQuickOptions = !_showQuickOptions;
          //       _showAttachmentOptions = false;
          //     });
          //   },
          // ),

          // Emoji button (placeholder)
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
            onPressed: () {},
          ),

          // Message input field
          Expanded(
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final img = _selectedImages[index];
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                icon: Icon(Icons.close, size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() => _selectedImages.removeAt(index));
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Message",
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => sendMessage(isButton: true),
                ),
              ],
            ),
          ),



          // Attach file button
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              setState(() {
                _showAttachmentOptions = !_showAttachmentOptions;
                _showQuickOptions = false;
              });
            },
          ),

          // Send button
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_selectedImages.isNotEmpty) {
                  for (var img in _selectedImages) {
                    sendImage(File(img.path));
                  }
                  setState(() {
                    _selectedImages.clear(); // clear previews after sending
                  });
                } else {
                  sendMessage(isButton: true);
                }
              },
            ),
          ),


        ],
      ),
    );
  }

  Future<void> _saveAvatarToPrefs(String username, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_$username', path);
  }

  Future<String?> _getSavedAvatar(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar_$username');
  }

  Widget _quickOptionsPopup() => _popupContainer([
    _popupButton(Icons.insert_drive_file, "Template"),
    // _popupButton(Icons.bolt, "Quick Replies"),
  ]);

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: "Search chats...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.black54),
      ),
      style: const TextStyle(color: Colors.black, fontSize: 18),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  Future<void> _openImagePickerDialog() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile>? pickedFiles = await picker.pickMultiImage(); // MULTIPLE
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      print("❌ pickMultiImage error: $e");
    }
  }

  Widget _popupButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: () {
        print("Tapped $label");
        setState(() {
          _showAttachmentOptions = false;
          _showQuickOptions = false;
        });

        if (onTap != null) onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.teal, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style:
                const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _popupContainer(List<Widget> children) {
    return Stack(
      children: [
        // semi-transparent background
        GestureDetector(
          onTap: () {
            setState(() {
              _showAttachmentOptions = false;
              _showQuickOptions = false;
            });
          },
          behavior: HitTestBehavior.translucent, // ✅ allow taps to pass through
          child: Container(
            color: Colors.black38, // optional: darken background
          ),
        ),
        // The popup itself
        Center(
          child: Material(
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    print("🔹 pickFile called");
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📄 File selected: ${result.files.single.name}')),
      );
    }
  }

  // Widget _chatBottomBar() {
  //   return BottomAppBar(
  //     color: Colors.teal,
  //     elevation: 8,
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: [
  //           _BottomIcon(
  //             icon: FontAwesomeIcons.folder,
  //             label: "Journeys",
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => const JourneysScreen()),
  //               );
  //             },
  //           ),
  //           const _BottomIcon(icon: FontAwesomeIcons.fileText, label: "Notes"),
  //           const _BottomIcon(icon: FontAwesomeIcons.calendar, label: "Reservations"),
  //           const _BottomIcon(icon: FontAwesomeIcons.shopify, label: "Shopify"),
  //           const _BottomIcon(icon: FontAwesomeIcons.shoppingBag, label: "Woo"),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _chatAppBar() {
    final userIndex = _chats.indexWhere((chat) => chat['name'] == _selectedUser);
    final user = userIndex != -1
        ? _chats[userIndex]
        : {
      'name': _selectedUser ?? 'Unknown',
      'avatar': '',
    };

    return SafeArea(
      top: true, // ensures it doesn’t overlap notch/status bar
      bottom: false,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactInfoScreen(
                name: user['name'],
                phone: _selectedPhone ?? "+91 0000000000",
                email: "arjun@example.com",
                country: "India",
                subscriptionStatus: "Active",
                createdAt: "2024-10-01",
                status: "Open",
                lastActivity: "2024-10-28",
                language: "English",
                aiBotEnabled: true,
                avatar: user['avatar'], // use the current one
                onAvatarUpdated: (newPath) async {
                  await _saveAvatarToPrefs(user['name'], newPath);
                  setState(() {
                    if (userIndex != -1) _chats[userIndex]['avatar'] = newPath;
                  });
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              FutureBuilder<String?>(
                future: _getSavedAvatar(user['name']),
                builder: (context, snapshot) {
                  final savedAvatar = snapshot.data;
                  final avatarToShow = savedAvatar ?? user['avatar'] ?? '';
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: avatarToShow.toString().startsWith('http')
                        ? NetworkImage(avatarToShow)
                        : (avatarToShow.isNotEmpty ? FileImage(File(avatarToShow)) as ImageProvider : null),
                    child: (avatarToShow.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  );
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    "tap here for contact info",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> saveMessagesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('messages', jsonEncode(_messages));
  }

  Future<void> loadMessagesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('messages');
    if (saved != null) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(saved));
      });
    }
  }

  Future<void> _loadTokenAndFetchChats() async {
    print("🔹 _loadTokenAndFetchChats called");
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    print("🔹 Loaded token: $_token");
    if (_token != null) _fetchConversationsAndPopulate();
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class ContactInfoScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String avatar;
  final String email;
  final String country;
  final String subscriptionStatus;

  // ✅ Chat details fields
  final String createdAt;
  final String status;
  final String lastActivity;
  final String language;
  final bool aiBotEnabled;

  final Function(String)? onAvatarUpdated;

  const ContactInfoScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.email,
    required this.country,
    required this.subscriptionStatus,
    required this.createdAt,
    required this.status,
    required this.lastActivity,
    required this.language,
    required this.aiBotEnabled,
    this.onAvatarUpdated,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  bool contactExpanded = false;
  bool chatExpanded = false;
  bool customExpanded = false;

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController countryCtrl;
  late TextEditingController statusCtrl;


  bool isEditing = false;


  bool aiBotEnabled = false;


  @override
  void initState() {
    super.initState();
    aiBotEnabled = widget.aiBotEnabled;


    nameCtrl = TextEditingController(text: widget.name);
    phoneCtrl = TextEditingController(text: widget.phone);
    emailCtrl = TextEditingController(text: widget.email);
    countryCtrl = TextEditingController(text: widget.country);
    statusCtrl = TextEditingController(text: widget.subscriptionStatus);

  }


  /// Image picker


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contact Info",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
            child: Text(
              isEditing ? "Save" : "Edit",
              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile section
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: NetworkImage(widget.avatar),
                ),

                const SizedBox(height: 12),
                Text(
                  widget.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            ),

            // Expansion Tiles
            _customExpansionTile(
              title: "Contact Details",
              expanded: contactExpanded,
              onTap: () => setState(() => contactExpanded = !contactExpanded),
            ),
            const SizedBox(height: 8),
            _customExpansionTile(
              title: "Chat Details",
              expanded: chatExpanded,
              onTap: () => setState(() => chatExpanded = !chatExpanded),
            ),
            const SizedBox(height: 8),
            _customExpansionTile(
              title: "Custom Fields",
              expanded: customExpanded,
              onTap: () => setState(() => customExpanded = !customExpanded),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customExpansionTile({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w500)),
        trailing: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.teal,
        ),
        onExpansionChanged: (_) => onTap(),
        children: [
          if (title == "Contact Details") _buildContactDetails(),
          if (title == "Chat Details") _buildChatDetails(),
          if (title == "Custom Fields")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text("Custom field info goes here...",
                  style: TextStyle(color: Colors.black54)),
            ),
        ],
      ),
    );
  }

  /// CONTACT DETAILS SECTION
  Widget _buildContactDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editableField("Name", nameCtrl.text, nameCtrl),
          SizedBox(height: 8),
          _editableField("Phone", phoneCtrl.text, phoneCtrl),
          SizedBox(height: 8),
          _editableField("Email", emailCtrl.text, emailCtrl),
          SizedBox(height: 8),
          _editableField("Country", countryCtrl.text, countryCtrl),
          SizedBox(height: 8),
          _editableField("Subscription Status", statusCtrl.text, statusCtrl),
        ],
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }



  /// CHAT DETAILS SECTION
  Widget _buildChatDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _readonlyField("Created At", widget.createdAt?.toString() ?? ""),
          SizedBox(height: 8),

          _readonlyField("Status", widget.status?.toString() ?? ""),
          SizedBox(height: 8),

          _readonlyField("Last Activity", widget.lastActivity?.toString() ?? ""),
          SizedBox(height: 8),

          _readonlyField("Language", widget.language?.toString() ?? ""),
          SizedBox(height: 8),

          // AI Bot Enabled Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AI Bot Enabled",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                  fontSize: 14,
                ),
              ),
              Switch(
                activeColor: Colors.teal,
                value: aiBotEnabled,
                onChanged: (value) {
                  setState(() => aiBotEnabled = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// Reusable readonly display field
  Widget _editableField(String label, String value, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 14),
        ),
        const SizedBox(height: 4),
        isEditing
            ? TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        )
            : Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            value.isNotEmpty ? value : "Not available",
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
      ],
    );
  }

}


