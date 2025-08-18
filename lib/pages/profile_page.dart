import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../utils/utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  String? _profileImageUrl;
  File? _pickedImageFile;
  String? _userStatus;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() => _loading = true);
    final profile = await UserService.getCurrentUser();
    if (profile != null) {
      _bioController.text = profile['bio'] ?? '';
      setState(() {
        _profileImageUrl = profile['profile_picture'];
        _userStatus = getUserStatus(profile['last_seen']);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImg() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (image != null) {
      setState(() {
        _pickedImageFile = File(image.path);
        //brisanje trenutne profilne slike sa servera
        _profileImageUrl = null;
      });
    }
  }

  void _saveUserData() async {
    setState(() => _saving = true);

    bool success = await UserService.updateProfile(
      bio: _bioController.text,
      profileImage: _pickedImageFile,
    );


    if (success) {
      setState(() {
        _pickedImageFile = null;
      });
      _loadUserData();
    }

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Uspešno azurirano!' : 'Greska pri azuriranju.'),
      ),
    );
    if (success) Navigator.pop(context);
  }


  Widget _buildProfilePicture() {

    return Column(
      children: [
        SizedBox(height: 10),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            (_pickedImageFile != null)
                ? CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[200],
              backgroundImage: FileImage(_pickedImageFile!),
            )
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                ? CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(getFullImageUrl(_profileImageUrl)),

            )
                : CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 54, color: Colors.white70),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _pickImg,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        TextButton.icon(
          onPressed: _pickImg,
          icon: Icon(Icons.edit, size: 18),
          label: Text('Promeni profilnu sliku'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Podesavanja naloga')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Podesavanja naloga')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfilePicture(),
              SizedBox(height: 18),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Unesi kratak opis o sebi...',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _userStatus == "Online" ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Status: $_userStatus',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              _saving
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveUserData,
                child: Text('Sacuvaj izmene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
