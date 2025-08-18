import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/conversation_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _grpNameController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  Set<String> _selectedUserIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _getUsers();
  }

  void _getUsers() async {
    final allUsers = await UserService.getUsers();
    print(allUsers);
    final id = await UserService.getCurrentId();
    setState(() {
      _users = allUsers.where((u) => u['id'] != id).toList();
      _selectedUserIds = {if (id != null) id};
      _loading = false;
    });
  }

  Future<void> _createGroup() async {
    final grpName = _grpNameController.text.trim();
    if (grpName.isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unesi naziv grupe i izaberi clanove!')),
      );
      return;
    }
    setState(() => _saving = true);
    final convId = await ConversationService.createGroup(
      gName: grpName,
      membersId: _selectedUserIds.toList(),
    );
    setState(() => _saving = false);
    if (convId != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Neuspesno kreiranje grupe.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kreiraj grupu')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _grpNameController,
              decoration: InputDecoration(
                labelText: 'Naziv grupe',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Izaberi clanove:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return CheckboxListTile(
                    title: Text(user['username']),
                    value: _selectedUserIds.contains(user['id']),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedUserIds.add(user['id']);
                        } else {
                          _selectedUserIds.remove(user['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            _saving
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              icon: Icon(Icons.group_add),
              label: Text('Kreiraj grupu'),
              onPressed: _createGroup,
            ),
          ],
        ),
      ),
    );
  }
}
