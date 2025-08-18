import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/conversation_service.dart';

enum userAction { add, remove }

class MngMembersPage extends StatefulWidget {
  final String conversationId;
  final userAction mod;
  final String? adminId;

  const MngMembersPage({
    super.key,
    required this.conversationId,
    required this.mod,
    this.adminId,
  });

  @override
  State<MngMembersPage> createState() => _MngMembersPageState();
}

class _MngMembersPageState extends State<MngMembersPage> {
  bool _loading = true;
  bool _submitChange = false;

  List<Map<String, String>> userList = [];
  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      userList.clear();
      selected.clear();
    });

    try {
      final conv = await ConversationService.getConv(widget.conversationId);
      if (conv == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greska: Konverzacija nije pronadjena.')),
        );
        return;
      }

      final List<String> currentMembers = [];
      final members = conv['members'];
        for (final m in members) {
           currentMembers.add(m); //proveri!!!!!!!!!!!!!!
          //if (m is Map && m['id'] != null) currentMembers.add(m['id'].toString());
        }

      final String? adminId = (widget.adminId ?? conv['admin'])?.toString(); //Proveri!!!!!!!!!!!!!!!!!!!!!!!!!

      List<Map<String, String>> updUsers = [];

      if (widget.mod == userAction.add) {
        final allUsers = await UserService.getUsers();
        for (final u in allUsers) {
          final id = (u['id']).toString();
          if (id.isEmpty) continue;
          if (!currentMembers.contains(id)) {
            updUsers.add({'id': id, 'username': (u['username']).toString()});
          }
        }
      } else {
        for (final memberId in currentMembers) {
          if (adminId != null && memberId == adminId) continue;
          final user = await UserService.getUser(memberId);
          if (user != null) {
            updUsers.add({'id': memberId, 'username': (user['username']).toString()});
          }
        }
      }

      setState(() {
        userList = updUsers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greska pri ucitavanju: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (selected.isEmpty) return;

    setState(() => _submitChange = true);

    bool response = false;
    try {
      if (widget.mod == userAction.add) {
        response = await ConversationService.addMembers(
          widget.conversationId,
          selected.toList(),
        );
      } else {
        response = await ConversationService.removeMembers(
          widget.conversationId,
          selected.toList(),
        );
      }
    } catch (e) {
      response = false;
    }

    if (!mounted) return;
    setState(() => _submitChange = false);

    if (response) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mod == userAction.add
                ? 'Članovi uspešno dodati.'
                : 'Članovi uspešno uklonjeni.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operacija nije uspela.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.mod == userAction.add;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdd ? 'Dodajte novog usera' : 'Uklonite clanove'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: userList.isEmpty
                ? Center(
              child: Text(
                isAdd
                    ? 'Nema korisnika koji nisu u grupi.'
                    : 'Nema clanova za uklanjanje.',
              ),
            )
                : ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                final id = user['id']!;
                final username = user['username'] ?? 'Nepoznat korisnik';
                final checked = selected.contains(id);

                return CheckboxListTile(
                  title: Text(username),
                  value: checked,
                  onChanged: _submitChange
                      ? null
                      : (val) {
                    setState(() {
                      if (val == true) {
                        selected.add(id);
                      } else {
                        selected.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitChange || selected.isEmpty ? null : _submit,
                child: _submitChange
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Potvrdi'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
