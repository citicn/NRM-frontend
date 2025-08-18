import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nrm_project_app/pages/profile_page.dart';
import 'package:nrm_project_app/pages/users_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/conversation_service.dart';
import 'chat_page.dart';
import 'create_group_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  String? _cUserId;

  @override
  void initState() {
    super.initState();
    _getAllConv();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _cUserId = prefs.getString('user_id');
      });
    });
  }

  //Ucitavanje
  void _getAllConv() {
    _conversationsFuture = ConversationService.getAllConv();
  }

  //Osvezi prepiske
  Future<void> _refreshConversations() async {
    setState(() {
      _getAllConv();
    });
    await _conversationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konverzacije'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Novi chat",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersPage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: Icon(Icons.group_add),
            tooltip: "Nova grupa",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateGroupPage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            tooltip: "Podesavanja profila",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Odjavi se",
            onPressed: () async {
              await AuthSrv.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshConversations,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _cUserId == null) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Greska: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 180),
                  Center(child: Text('Nema konverzacija.')),
                ],
              );
            } else {
              final conversations = snapshot.data!;
              final filterConvs = conversations.where((c) {
                final isGroup = c['conversation_type'] == 'group';
                final lastMsg = c['last_message'];
                if (isGroup) return true;
                return lastMsg != null && (lastMsg['text']?.isNotEmpty ?? false);
              }).toList();
              return ListView.builder(
                itemCount: filterConvs.length,
                itemBuilder: (context, index) {
                  final c = filterConvs[index];
                  String grpTitle = '';
                  if (c['conversation_type'] == 'group') {
                    grpTitle = c['name'] ?? 'Grupa';
                  } else {
                    final m = c['members'] as List<dynamic>;
                    final otherUsr = m.firstWhere(
                          (u2) => u2['id'] != _cUserId
                    );
                    grpTitle = otherUsr['username'] ?? 'NN';
                  }

                  final lastMsg = c['last_message'];
                  String preview = '';
                  final isGroup = c['conversation_type'] == 'group';
                  if (lastMsg != null && (lastMsg['text']?.isNotEmpty ?? false)) {
                    preview = lastMsg['text'];
                  } else if (isGroup) {
                    preview = 'Nema poruka.';
                  }

                  String timeStr = '';
                  if (lastMsg != null && lastMsg['created_at'] != null && lastMsg['created_at'].isNotEmpty) {
                    try {
                      final dateTime = DateTime.parse(lastMsg['created_at']);
                      timeStr = DateFormat('HH.mm - d/M/y').format(dateTime);
                    } catch (_) {
                      timeStr = lastMsg['created_at'].toString();
                    }
                  }

                  return ListTile(
                    title: Text(grpTitle),
                    subtitle: Text(preview.isEmpty ? 'Nema poruka.' : preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(timeStr),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            conversationId: c['id'].toString(),
                            otherUser: grpTitle,
                          ),
                        ),
                      );
                      _refreshConversations();
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
