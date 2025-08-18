import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/messages_service.dart';
import '../services/user_service.dart';
import '../services/conversation_service.dart';
import 'mng_members_page.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUser;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _myUserId;
  List<Map<String, dynamic>> _members = [];
  String _conversationType = 'private';
  bool _membersLoading = true;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _messagesFuture = MessageService.getMsgs(widget.conversationId);
    UserService.getCurrentId().then((id) {
      setState(() {
        _myUserId = id;
      });
    });
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final conv = await ConversationService.getConv(widget.conversationId);
    if (conv != null) {
      final membersRaw = conv['members'];
      List<Map<String, dynamic>> memberList = [];
        for (var memberId in membersRaw) {
            final user = await UserService.getUser(memberId);
            if (user != null) {
              memberList.add({"id": memberId, "username": user['username']});

          }
        }
      setState(() {
        _members = memberList;
        _conversationType = conv['conversation_type'] ?? 'private';
        _adminId = conv['admin'];
        _membersLoading = false;
      });
    } else {
      setState(() {
        _membersLoading = false;
      });
    }
  }

  void _refreshMessages() {
    setState(() {
      _messagesFuture = MessageService.getMsgs(widget.conversationId);
    });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final success = await MessageService.sendMsg(
      convId: widget.conversationId,
      msgText: text,
    );

    if (success) {
      _msgController.clear();
      _refreshMessages();
      await Future.delayed(Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri slanju poruke!')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${widget.otherUser}'),
          actions: (_conversationType == 'group' && _myUserId != null && _adminId == _myUserId)
              ? [
            IconButton(
              tooltip: 'Dodaj clanove',
              icon: Icon(Icons.group_add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MngMembersPage(
                      conversationId: widget.conversationId,
                      mod: userAction.add,
                      adminId: _adminId,
                    ),
                  ),
                );
                await _loadMembers();
                _refreshMessages();
              },
            ),

            IconButton(
              tooltip: 'Ukloni clanove',
              icon: Icon(Icons.person_remove),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MngMembersPage(
                      conversationId: widget.conversationId,
                      mod: userAction.remove,
                      adminId: _adminId,
                    ),
                  ),
                );
                await _loadMembers();
                _refreshMessages();
              },
            ),

            IconButton(
              tooltip: 'Obrisi grupu',
              icon: Icon(Icons.delete_forever),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Brisanje grupe'),
                    content: Text('Da li ste sigurni da zelite da obrisete grupu?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Otkazi'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Obrisi'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final ok = await ConversationService.deleteGroup(widget.conversationId);
                  if (ok) {
                    if (!mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Brisanje grupe nije uspelo.')),
                    );
                  }
                }
              },
            ),
          ]
              : null,
        ),
      body: _membersLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _myUserId == null) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Greska: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nema poruka.'));
                } else {
                  final messages = snapshot.data!;
                  final memberMap = {
                    for (var m in _members) m['id']: m['username']
                  };
                  final isGroup = _conversationType == 'group';

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final text = msg['text'] ?? '';
                      final createdAt = msg['created_at'];
                      final isMine = msg['sender_id'] == _myUserId;

                      String time = '';
                      if (createdAt != null && createdAt.isNotEmpty) {
                        try {
                          final dateTime = DateTime.parse(createdAt);
                          time = DateFormat('HH:mm').format(dateTime);
                        } catch (_) {
                          time = createdAt.toString().substring(11, 16);
                        }
                      }

                      final senderUsername = memberMap[msg['sender_id']] ?? '';
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          color: isMine ? Colors.blue[200] : Colors.grey[200],
                          margin: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: isMine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (isGroup && !isMine)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3.0, left: 2),
                                    child: Text(
                                      senderUsername,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (text.isNotEmpty)
                                  Text(
                                    text,
                                    style: TextStyle(fontSize: 16),
                                    textAlign: isMine ? TextAlign.right : TextAlign.left,
                                  ),
                                SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                        hintText: 'Unesi poruku...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Osveži poruke",
        child: Icon(Icons.refresh),
        onPressed: _refreshMessages,
      ),
    );
  }
}
