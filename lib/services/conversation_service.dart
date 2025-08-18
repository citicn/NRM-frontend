import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConversationService {
  static const String bUrl = 'http://10.0.2.2:5000';


  //pronalazi vec postojecu ili kreira novu konverzaciju -- koristi sa UserProfilePage
  static Future<String?> findCreateConv(String otherUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');


    final fUrl = Uri.parse('$bUrl/conversations/find');
    final fResponse = await http.post(
      fUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"other_user_id": otherUserId}),
    );

    if (fResponse.statusCode == 200) {
      final data = jsonDecode(fResponse.body);
      return data['id'].toString();
    }


    final cUrl = Uri.parse('$bUrl/conversations/create');
    final cResponse = await http.post(
      cUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "members": [otherUserId],
        "conversation_type": "private"
      }),
    );
    if (cResponse.statusCode == 201) {
      final data = jsonDecode(cResponse.body);
      print(data['id'].toString());
      return data['id'].toString();
    } else {
      return null;
    }
  }


  //vracanje svih konverzacija
  static Future<List<Map<String, dynamic>>> getAllConv() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$bUrl/conversations');

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
      throw Exception('Neuspesno vracanje korisnika');
    }
  }


  //vracanje odredjene konverzacije
  static Future<Map<String, dynamic>?> getConv(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$bUrl/conversations/$conversationId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

//kreiranje grupe
  static Future<String?> createGroup({
    required String gName,
    required List<String> membersId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$bUrl/conversations/create');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'members': membersId,
        'conversation_type': 'group',
        'name': gName,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      return null;
    }
  }

 //dodaj nove clanove u grupu
  static Future<bool> addMembers(String conversationId, List<String> userIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$bUrl/conversations/$conversationId/add_members');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'members_id': userIds}),
    );

    return response.statusCode == 200;
  }

  //brisi clanove iz grupe
  static Future<bool> removeMembers(String conversationId, List<String> usersId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$bUrl/conversations/$conversationId/remove_members');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'members_id': usersId}),
    );

    return response.statusCode == 200;
  }
  //brisanje grupe
  static Future<bool> deleteGroup(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$bUrl/conversations/$conversationId');
    final resp = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return resp.statusCode == 200;
  }

}
