import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/utils.dart';
import 'users_profile_page.dart';


class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String? _cUserId;

  @override
  void initState() {
    super.initState();
    _usersFuture = UserService.getUsers();
    UserService.getCurrentId().then((id) {
      setState(() {
        _cUserId = id;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Korisnici')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Greska: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nema korisnika.'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                if (user['id'].toString() == (_cUserId ?? '')) return SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:NetworkImage(getFullImageUrl(user['profile_picture']))

                  ),
                  title: Text(user['username']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: user['id']),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
