import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';
class AuthSrv {
  static const String bUrl = 'http://10.0.2.2:5000';

  static Future<Map<String, dynamic>?> login(String username,
      String password) async {
    final url = Uri.parse('$bUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();

      prefs.setString('token', data['access_token']);
      prefs.setString('user_id', data['user']['id']);
      prefs.setString('username', data['user']['username']);


      await CryptoService.ensKeypairAndRegister();

      return data;

    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register(String username, String password) async {
    final url = Uri.parse('$bUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('pub_registered');
  }
}