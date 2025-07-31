import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/conversation_service.dart';
import '../utils/utils.dart';
import 'chat_page.dart';


class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  bool _loading = true;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    final user = await UserService.fetchOtherProfile(widget.userId);
    setState(() {
      userData = user;
      _loading = false;
    });
  }

  Future<void> _openChat() async {
    if (userData == null) return;
    setState(() => _openingChat = true);
    final convId = await ConversationService.findCreateConv(userData!['id']);
    setState(() => _openingChat = false);
    if (convId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: convId,
            otherUser: userData!['username'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nije moguce otvoriti chat.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Korisnik nije pronajden.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Profil korisnika')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 150,
                backgroundColor: Colors.grey[300],
                backgroundImage: NetworkImage(getFullImageUrl(userData!['profile_picture']))
              ),
              SizedBox(height: 24),
              Text(
                userData!['username'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.circle,
                    color: getUserStatus(userData!['last_seen']) == "Online" ? Colors.green : Colors.red,
                    size: 14,
                  ),

                  SizedBox(width: 8),

                  Text(
                    "Status: ${getUserStatus(userData!['last_seen'])}",
                    style: TextStyle(fontSize: 17, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: 14),

              Text(
                "Bio: ${userData!['bio'] ?? ''}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              SizedBox(height: 34),
              Text(
                "Zapocni konverzaciju",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10),

              _openingChat
                  ? CircularProgressIndicator()
                  : IconButton(
                icon: Icon(Icons.message_rounded,
                    size: 44, color: Colors.blue),
                tooltip: "Posalji poruku",
                onPressed: _openChat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
