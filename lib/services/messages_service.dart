import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'crypto_service.dart';

class MessageService {
  static const String baseUrl = AuthSrv.bUrl;


  static Future<bool> sendMsg({
    required String convId,
    String? msgText,
  }) async {
    if (msgText == null || msgText.trim().isEmpty) return false;


    await CryptoService.ensKcForConv(convId);

    final enc = await CryptoService.encryptMsgForConv(convId, msgText.trim());

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return false;

    final url = Uri.parse('$baseUrl/messages/send');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "conversation_id": convId,
        "ciphertext": enc.ciphertextB64,
        "nonce": enc.nonceB64,
        "key_version": enc.keyVersion,
      }),
    );

    return resp.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getMsgs(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return [];

    await CryptoService.ensKcForConv(conversationId);

    final url = Uri.parse('$baseUrl/messages/$conversationId');
    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Neuspesno vracanje poruka');
    }

    final List<dynamic> data = jsonDecode(resp.body);
    final out = <Map<String, dynamic>>[];

    for (final m in data.cast<Map<String, dynamic>>()) {
      final kv = (m['key_version'] as num).toInt();
      final ctB64 = m['ciphertext'] as String?;
      final nonceB64 = m['nonce'] as String?;
      String text = '';

      if (ctB64 != null && nonceB64 != null) {
        try {
          text = await CryptoService.decryptMsgForConv(
            conversationId: conversationId,
            keyVersion: kv,
            ciphertextB64: ctB64,
            nonceB64: nonceB64,
          );
        } catch (_) {
          text = '***nije moguće desifrovati';
        }
      }

      out.add({
        'id': m['id'],
        'sender_id': m['sender_id'],
        'text': text,
        'created_at': m['created_at'],
      });
    }

    return out;
  }
}
