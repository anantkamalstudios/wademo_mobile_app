import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'BottomOptionsScreens.dart';


class ChatScreen extends StatefulWidget {
  final Function(bool)? onChatStateChange;
  const ChatScreen({super.key, this.onChatStateChange});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isChatOpen = false;
  bool _showQuickOptions = false;
  bool _showAttachmentOptions = false;
  bool _isSearching = false; // search mode
  String _searchQuery = ""; // search text
  String? _selectedUser;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedFile;

  final TextEditingController _messageController = TextEditingController(); // ✅ added controller

  Future<void> _saveAvatarToPrefs(String username, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_$username', path);
  }

  Future<String?> _getSavedAvatar(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar_$username');
  }

  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Arjun Das Mygate',
      'message': 'Hey, I got to know you’re amid a design task, ATB for same!',
      'time': '12:35 PM',
      'unread': 10,
      'avatar': 'https://i.pravatar.cc/100?img=1',
    },
    {
      'name': 'Elisa das Zoho',
      'message': 'Japan looks amazing!',
      'time': 'Yesterday',
      'unread': 0,
      'avatar': 'https://i.pravatar.cc/100?img=2',
    },
    {
      'name': 'Brian Kapoor',
      'message': 'See you soon!',
      'time': '9:20 AM',
      'unread': 1,
      'avatar': 'https://i.pravatar.cc/100?img=3',
    },
    {
      'name': 'Chaitra V',
      'message': 'Thanks for sharing the report.',
      'time': '8:10 PM',
      'unread': 3,
      'avatar': 'https://i.pravatar.cc/100?img=4',
    },
    {
      'name': 'Chaitra V',
      'message': 'Thanks for sharing the report.',
      'time': '8:10 PM',
      'unread': 3,
      'avatar': 'https://i.pravatar.cc/100?img=4',
    },
    {
      'name': 'Chaitra V',
      'message': 'Thanks for sharing the report.',
      'time': '8:10 PM',
      'unread': 3,
      'avatar': 'https://i.pravatar.cc/100?img=4',
    },
    {
      'name': 'Chaitra V',
      'message': 'Thanks for sharing the report.',
      'time': '8:10 PM',
      'unread': 3,
      'avatar': 'https://i.pravatar.cc/100?img=4',
    },
    {
      'name': 'Chaitra V',
      'message': 'Thanks for sharing the report.',
      'time': '8:10 PM',
      'unread': 3,
      'avatar': 'https://i.pravatar.cc/100?img=4',
    },
  ];

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey where are you now ?', 'isMe': false, 'time': '11:40'},
    {'text': 'Good morning, In Chennai 😎', 'isMe': true, 'time': '11:43'},
    {'text': 'I will write from Japan', 'isMe': true, 'time': '17:47'},
    {'text': 'Good bye!', 'isMe': true, 'time': '17:47'},
    {'text': 'Japan looks amazing!', 'isMe': true, 'time': '10:10'},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredChats = _chats
        .where((chat) => chat['name']
        .toString()
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a['name']
          .toString()
          .toLowerCase()
          .compareTo(b['name'].toString().toLowerCase()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                setState(() {
                  _isSearching = true;
                });
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
            icon: const Icon(Icons.more_vert, color: Colors.black54),
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
            });
            widget.onChatStateChange?.call(false);
          },
        )
            : _isSearching
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = "";
            });
          },
        )
            : null,
      ),
      body: _isChatOpen ? _chatView() : _chatListView(filteredChats),
      bottomNavigationBar: _isChatOpen ? _chatBottomBar() : null,
    );
  }

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

  Widget _chatListView(List<Map<String, dynamic>> chats) {
    if (chats.isEmpty) {
      return const Center(
        child: Text("No chats found",
            style: TextStyle(color: Colors.black54, fontSize: 16)),
      );
    }

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          onTap: () {
            setState(() {
              _isChatOpen = true;
              _selectedUser = chat['name'];
              _isSearching = false;
              _searchQuery = "";
            });
            widget.onChatStateChange?.call(true);
          },
          leading: FutureBuilder<String?>(
            future: _getSavedAvatar(chat['name']),
            builder: (context, snapshot) {
              final savedAvatar = snapshot.data;
              final avatarToShow = savedAvatar ?? chat['avatar'];
              return CircleAvatar(
                radius: 24,
                backgroundImage: avatarToShow.toString().startsWith('http')
                    ? NetworkImage(avatarToShow)
                    : FileImage(File(avatarToShow)) as ImageProvider,
              );
            },
          ),
          title: Text(chat['name'],
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          subtitle: Row(
            children: [
              const Icon(Icons.done_all, size: 14, color: Colors.teal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(chat['message'],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(chat['time'],
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              if (chat['unread'] > 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${chat['unread']}',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chatView() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg['isMe']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg['isMe']
                            ? const Color(0xFFE7FFDB)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: msg['isMe']
                              ? const Radius.circular(12)
                              : const Radius.circular(0),
                          bottomRight: msg['isMe']
                              ? const Radius.circular(0)
                              : const Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 2,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(msg['text'],
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(msg['time'],
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black54)),
                              if (msg['isMe']) ...[
                                const SizedBox(width: 3),
                                const Icon(Icons.done_all,
                                    size: 14, color: Colors.teal),
                              ],
                            ],
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
                child: Row(
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (_selectedFile != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📄 ${_selectedFile!.path.split('/').last}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                _chatInput(),
                if (_showQuickOptions)
                  Positioned(
                    bottom: 65,
                    left: 0,
                    right: 0,
                    child: _quickOptionsPopup(),
                  ),
                if (_showAttachmentOptions)
                  Positioned(
                    bottom: 65,
                    left: 0,
                    right: 0,
                    child: _attachmentPopup(),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ send message function
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': TimeOfDay.now().format(context),
      });
      _messageController.clear();
    });

    // ✅ Simulate auto incoming message
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add({
          'text': _generateAutoReply(text),
          'isMe': false,
          'time': TimeOfDay.now().format(context),
        });
      });
    });
  }

  /// Simple auto-reply generator
  String _generateAutoReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello')) {
      return "Hey there! 👋";
    } else if (lower.contains('how are you')) {
      return "I'm doing great! How about you?";
    } else if (lower.contains('bye')) {
      return "Goodbye! Talk soon 👋";
    } else if (lower.contains('thanks') || lower.contains('thank')) {
      return "You're welcome 😊";
    } else {
      return "Got it 👍";
    }
  }


  Widget _chatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon:
            const Icon(Icons.bolt_outlined, color: Colors.amber, size: 28),
            onPressed: () {
              setState(() {
                _showQuickOptions = !_showQuickOptions;
                _showAttachmentOptions = false;
              });
            },
          ),
          IconButton(
            icon:
            const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController, // ✅ controller added
              decoration: const InputDecoration(
                hintText: "Message",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(), // ✅ press enter to send
            ),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              setState(() {
                _showAttachmentOptions = !_showAttachmentOptions;
                _showQuickOptions = false;
              });
            },
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage, // ✅ send on tap
            ),
          ),
        ],
      ),
    );
  }

  // Remaining helper popups unchanged
  Widget _quickOptionsPopup() => _popupContainer([
    _popupButton(Icons.insert_drive_file, "Template"),
    _popupButton(Icons.bolt, "Quick Replies"),
  ]);

  Widget _attachmentPopup() => _popupContainer([
    _popupButton(
      Icons.image_outlined,
      "Image",
      onTap: () {
        setState(() => _showAttachmentOptions = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openImagePickerDialog();
        });
      },
    ),
    _popupButton(
      Icons.picture_as_pdf_outlined,
      "File",
      onTap: () {
        setState(() => _showAttachmentOptions = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pickFile();
        });
      },
    ),
  ]);

  void _openImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Select Image"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (pickedFile != null) {
                    setState(() => _selectedImage = File(pickedFile.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📸 Image selected: ${pickedFile.name}')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text("Take a Photo"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (pickedFile != null) {
                    setState(() => _selectedImage = File(pickedFile.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📷 Photo captured: ${pickedFile.name}')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _popupButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
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
            Text(label, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _popupContainer(List<Widget> children) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📄 File selected: ${result.files.single.name}')),
      );
    }
  }

  Widget _chatBottomBar() {
    return BottomAppBar(
      color: Colors.teal,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomIcon(
              icon: FontAwesomeIcons.folder,
              label: "Journeys",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JourneysScreen()), // replace with JourneysScreen()
                );
              },
            ),
            const _BottomIcon(icon: FontAwesomeIcons.fileText, label: "Notes"),
            const _BottomIcon(icon: FontAwesomeIcons.calendar, label: "Reservations"),
            const _BottomIcon(icon: FontAwesomeIcons.shopify, label: "Shopify"),
            const _BottomIcon(icon: FontAwesomeIcons.shoppingBag, label: "Woo"),
          ],
        ),
      ),
    );
  }

  Widget _chatAppBar() {
    final userIndex = _chats.indexWhere((chat) => chat['name'] == _selectedUser);
    final user = _chats[userIndex];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactInfoScreen(
              name: user['name'],
              phone: "+91 9823472345",
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
                // ✅ Save it locally for persistence
                await _saveAvatarToPrefs(user['name'], newPath);

                // ✅ Update chat list data in memory
                setState(() {
                  user['avatar'] = newPath;
                });
              },
            ),
          ),
        );
      },
      child: Row(
        children: [
          FutureBuilder<String?>(
            future: _getSavedAvatar(user['name']),
            builder: (context, snapshot) {
              final savedAvatar = snapshot.data;
              final avatarToShow = savedAvatar ?? user['avatar'];
              return CircleAvatar(
                radius: 20,
                backgroundImage: avatarToShow.toString().startsWith('http')
                    ? NetworkImage(avatarToShow)
                    : FileImage(File(avatarToShow)) as ImageProvider,
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
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const Text(
                "tap here for contact info",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
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

  bool aiBotEnabled = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    aiBotEnabled = widget.aiBotEnabled;
    _loadSavedImage();
  }

  /// Load saved image path from SharedPreferences
  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('saved_profile_image');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _pickedImage = File(path);
      });
    }
  }

  /// Save image path to SharedPreferences
  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_profile_image', path);
  }

  /// Image picker
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                final pickedFile =
                await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _pickedImage = File(pickedFile.path);
                  });
                  await _saveImagePath(pickedFile.path);
                  widget.onAvatarUpdated?.call(pickedFile.path);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text("Take a Photo"),
              onTap: () async {
                final pickedFile =
                await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _pickedImage = File(pickedFile.path);
                  });
                  await _saveImagePath(pickedFile.path);
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
            onPressed: () {},
            child: const Text(
              "Edit",
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : NetworkImage(widget.avatar) as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 2,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
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
                  if (_pickedImage != null) {
                    widget.onAvatarUpdated?.call(_pickedImage!.path);
                  }
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
          _readonlyField("Name", widget.name),
          const SizedBox(height: 8),
          _readonlyField("Phone", widget.phone),
          const SizedBox(height: 8),
          _readonlyField("Email", widget.email),
          const SizedBox(height: 8),
          _readonlyField("Country", widget.country),
          const SizedBox(height: 8),
          _readonlyField("Subscription Status", widget.subscriptionStatus),
        ],
      ),
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
          _readonlyField("Created At", widget.createdAt),
          const SizedBox(height: 8),
          _readonlyField("Status", widget.status),
          const SizedBox(height: 8),
          _readonlyField("Last Activity", widget.lastActivity),
          const SizedBox(height: 8),
          _readonlyField("Language", widget.language),
          const SizedBox(height: 8),

          // ✅ AI Bot Enabled (Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AI Bot Enabled",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                    fontSize: 14),
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
  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
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


