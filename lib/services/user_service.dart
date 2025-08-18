import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  //vracanje svih usera
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/users');
    print(token);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      //print(${response.body}');
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Neuspesno vracanje korisnika');
    }
  }

  //vracanje trenutnog usera
  static Future<String?> getCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  //azuriranje profila
  static Future<bool> updateProfile({
    String? bio,
    File? profileImage
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');
    final url = Uri.parse('$baseUrl/users/$userId');

    var request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer $token';

    if (bio != null) request.fields['bio'] = bio;

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', profileImage.path),
      );
    }

    final response = await request.send();

    return response.statusCode == 200;
  }

  //ucitavanje profila trenutnog usera
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/users/${userId}');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  //vracenje profila drugog usera
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }


}
