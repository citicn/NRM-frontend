import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MessageService {
  static const String baseUrl = 'http://10.0.2.2:5000';

//slanje poruke
  static Future<bool> sendMsg({
    required String convId,
    String? msgText,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/messages/send');

    final Map<String, dynamic> conv = {
      "conversation_id": convId,
    };
    if (msgText != null && msgText.isNotEmpty) conv['text'] = msgText;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(conv),
    );

    return response.statusCode == 201;
  }

  //vracanje poruka
  static Future<List<Map<String, dynamic>>> getMsgs(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/messages/$conversationId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Neuspesno vracanje poruka');
    }
  }
}
