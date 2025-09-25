import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/conversation_service.dart';
import '../services/crypto_service.dart';
import 'chat_page.dart';
import 'create_group_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'users_page.dart';

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

  void _getAllConv() {
    _conversationsFuture = ConversationService.getAllConv();
  }

  Future<void> _refreshConversations() async {
    setState(() {
      _getAllConv();
    });
    await _conversationsFuture;
  }

  Future<String> _lastMsgPreview(Map<String, dynamic> conv) async {
    final lastMsg = conv['last_message'];
    if (lastMsg == null) return 'Nema poruka.';

    final oldMsg = (lastMsg['text'] as String?);
    if (oldMsg != null && oldMsg.trim().isNotEmpty) {
      return oldMsg;
    }

    final ctB64 = lastMsg['ciphertext'] as String?;
    final nonceB64 = lastMsg['nonce'] as String?;
    final kv = lastMsg['key_version'];
    final int? keyVersion = (kv is num)
        ? kv.toInt()
        : int.tryParse(kv?.toString() ?? '');

    if (ctB64 != null && nonceB64 != null && keyVersion != null && keyVersion > 0) {
      try {
        final convId = conv['id'].toString();
        await CryptoService.ensKcForConv(convId);
        final text = await CryptoService.decryptMsgForConv(
          conversationId: convId,
          keyVersion: keyVersion,
          ciphertextB64: ctB64,
          nonceB64: nonceB64,
        );
        if (text.trim().isNotEmpty) return text;
      } catch (_) {
        return '***nije moguce desifrovati';
      }
    }

    return 'Nema poruka.';
  }

  String _formatLastTimeMsg(dynamic lastMsg) {
    if (lastMsg == null) return '';
    final createdAt = lastMsg['created_at'];
    if (createdAt == null || createdAt.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt.toString());
      return DateFormat('HH.mm - d/M/y').format(dt);
    } catch (_) {
      return createdAt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konverzacije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Novi chat",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersPage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: "Nova grupa",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Podešavanja profila",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) => _refreshConversations());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Odjavi se",
            onPressed: () async {
              await AuthSrv.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
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
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Nema konverzacija.')),
                ],
              );
            } else {
              final conversations = snapshot.data!;


              final items = conversations;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final c = items[index];

                  String title;
                  if (c['conversation_type'] == 'group') {
                    title = (c['name'] as String?) ?? 'Grupa';
                  } else {
                    final m = (c['members'] as List<dynamic>);
                    final otherUsr = m.firstWhere(
                          (u2) => u2['id'] != _cUserId,
                      orElse: () => {'username': 'NN'},
                    );
                    title = (otherUsr['username'] as String?) ?? 'NN';
                  }

                  final lastMsg = c['last_message'];
                  final timeStr = _formatLastTimeMsg(lastMsg);

                  return ListTile(
                    title: Text(title),
                    subtitle: FutureBuilder<String>(
                      future: _lastMsgPreview(c),
                      builder: (context, snap) {
                        final txt = snap.data ?? (snap.connectionState == ConnectionState.waiting
                            ? 'Učitavanje...'
                            : 'Nema poruka.');
                        return Text(
                          txt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    trailing: Text(timeStr),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            conversationId: c['id'].toString(),
                            otherUser: title,
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
