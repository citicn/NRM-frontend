
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class CryptoService {
  static final _storage = const FlutterSecureStorage();
  static final X25519 _alg = X25519();

  static final Map<String, Uint8List> _kcMem = {};

  static final Map<String, int> _convVersion = {};

  static Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid == null || uid.isEmpty) {
      throw Exception('Nema user_id u storage-u');
    }
    return uid;
  }

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    var t = prefs.getString('access_token');
    t ??= prefs.getString('token'); // legacy
    if (kDebugMode) print('[crypto] getToken -> ${t == null ? "null" : "len=${t.length}"}');
    if (t == null || t.isEmpty) {
      throw Exception('Nema access token-a u storage-u.');
    }
    return t;
  }

  static Future<String> _kpTagForCurrentUser() async {
    final uid = await _getCurrentUserId();
    return 'x25519_keypair_v1_$uid';
  }

  static String _ck(String convId, int v) => '$convId|v$v';

  static Future<Uint8List> _hkdfSha256({
    required List<int> ikm,
    List<int>? salt,
    required List<int> info,
    required int length,
  }) async {
    final macAlg = Hmac.sha256();

    final saltKey = SecretKey(
      salt == null || salt.isEmpty ? List<int>.filled(32, 0) : salt,
    );
    final prkMac = await macAlg.calculateMac(ikm, secretKey: saltKey);
    final prk = SecretKey(prkMac.bytes);

    final input = <int>[...info, 0x01];
    final t1Mac = await macAlg.calculateMac(input, secretKey: prk);
    final t1 = t1Mac.bytes;

    return Uint8List.fromList(t1.sublist(0, length));
  }

  static Future<SimpleKeyPairData> _loadOrCreateKeypair() async {
    final tag = await _kpTagForCurrentUser();
    final saved = await _storage.read(key: tag);
    if (saved != null) {
      final map = jsonDecode(saved) as Map<String, dynamic>;
      final privBytes = base64Decode(map['priv'] as String);
      final pubBytes  = base64Decode(map['pub'] as String);
      return SimpleKeyPairData(
        privBytes,
        publicKey: SimplePublicKey(pubBytes, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
    }

    final gen = await _alg.newKeyPair();
    final SimplePublicKey pub = await gen.extractPublicKey() as SimplePublicKey;
    final privBytes = await gen.extractPrivateKeyBytes();

    await _storage.write(
      key: tag,
      value: jsonEncode({'priv': base64Encode(privBytes), 'pub': base64Encode(pub.bytes)}),
    );

    return SimpleKeyPairData(
      privBytes,
      publicKey: pub,
      type: KeyPairType.x25519,
    );
  }

  static Future<void> _handleWrapped(String conversationId, String body) async {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final int keyVersion = data['key_version'];
    final ck = _ck(conversationId, keyVersion);
    if (_kcMem.containsKey(ck)) {
      _convVersion[conversationId] = keyVersion;
      return;
    }

    final kc = await _unwrapKc(
      conversationId: conversationId,
      keyVersion: keyVersion,
      ephemeralPubB64: data['ephemeral_pub'],
      nonceB64: data['nonce'],
      wrappedB64: data['wrapped'],
    );
    _kcMem[ck] = kc;
    _convVersion[conversationId] = keyVersion;
  }

  static Future<Uint8List> _unwrapKc({
    required String conversationId,
    required int keyVersion,
    required String ephemeralPubB64,
    required String nonceB64,
    required String wrappedB64,
  }) async {
    final kp = await _loadOrCreateKeypair();

    final ephBytes = base64Decode(ephemeralPubB64);
    if (ephBytes.length != 32) {
      throw Exception('Ephemeral public key len != 32 (got ${ephBytes.length})');
    }
    final remotePub = SimplePublicKey(ephBytes, type: KeyPairType.x25519);

    final shared = await _alg.sharedSecretKey(keyPair: kp, remotePublicKey: remotePub);
    final ikm = await shared.extractBytes();
    if (ikm.isEmpty) {
      throw Exception('Shared secret is empty');
    }
    if (kDebugMode) print('unwrap shared.len=${ikm.length}');

    final info = utf8.encode('$conversationId|v$keyVersion');
    final kekBytes = await _hkdfSha256(ikm: ikm, salt: null, info: info, length: 32);
    if (kekBytes.isEmpty) {
      throw Exception('HKDF derived k empty');
    }
    if (kDebugMode) print('unwrap kek.len=${kekBytes.length}');
    final kek = SecretKey(kekBytes);

    final aes = AesGcm.with256bits();
    final nonce = base64Decode(nonceB64);
    if (nonce.length != 12) {
      throw Exception('Nonce len != 12 (got ${nonce.length})');
    }
    final wrapped = base64Decode(wrappedB64);
    const tagLen = 16;
    if (wrapped.length < tagLen) {
      throw Exception('Wrapped kratak (len=${wrapped.length})');
    }
    final ct = wrapped.sublist(0, wrapped.length - tagLen);
    final mac = Mac(wrapped.sublist(wrapped.length - tagLen));
    final aad = info;

    if (kDebugMode) {
      print('unwrap ct.len=${ct.length} tag.len=$tagLen nonce.len=${nonce.length}');
    }

    final clear = await aes.decrypt(
      SecretBox(ct, nonce: nonce, mac: mac),
      secretKey: kek,
      aad: aad,
    );
    return Uint8List.fromList(clear);
  }

  static Uint8List _randBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  static Future<void> ensKeypairAndRegister() async {
    final kp = await _loadOrCreateKeypair();

    final token = await _getToken();

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('pub_registered') == true) {
      if (kDebugMode) print('vec registrovan pub');
      return;
    }

    final SimplePublicKey pub = await kp.extractPublicKey() as SimplePublicKey;
    final pubB64 = base64Encode(pub.bytes);

    final url = Uri.parse('${AuthSrv.bUrl}/keys/register');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'public_key_x25519': pubB64}),
    );

    if (kDebugMode) print('/keys/register -> ${resp.statusCode}');
    if (resp.statusCode == 200) {
      await prefs.setBool('pub_registered', true);
    } else if (resp.statusCode == 401) {
      throw Exception('JWT 401 pri registraciji javnog kljuca. Uloguj se ponovo.');
    } else {
      throw Exception('Registracija javnog kljuca neuspesna: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> ensKcForConv(String conversationId) async {
    final token = await _getToken();
    final wrappedUrl = Uri.parse('${AuthSrv.bUrl}/conversations/$conversationId/wrapped-key');

    final resp = await http.get(wrappedUrl, headers: {'Authorization': 'Bearer $token'});
    if (kDebugMode) print('GET wrapped-key -> ${resp.statusCode}');
    if (resp.statusCode != 200) {
      if (resp.statusCode == 400) {
        final initUrl = Uri.parse('${AuthSrv.bUrl}/conversations/$conversationId/init-crypto');
        final initResp = await http.post(initUrl, headers: {'Authorization': 'Bearer $token'});
        if (kDebugMode) print('POST init-crypto -> ${initResp.statusCode}');
        if (initResp.statusCode == 200) {
          final resp2 = await http.get(wrappedUrl, headers: {'Authorization': 'Bearer $token'});
          if (resp2.statusCode != 200) {
            throw Exception('Wrapped-key error: ${resp2.statusCode}');
          }
          await _handleWrapped(conversationId, resp2.body);
          return;
        }
      }
      throw Exception('Wrapped-key error: ${resp.statusCode} ${resp.body}');
    }

    await _handleWrapped(conversationId, resp.body);
  }


  static int? getCurrVersion(String conversationId) {
    return _convVersion[conversationId];
  }

  static Uint8List? getKc(String conversationId, int keyVersion) {
    return _kcMem[_ck(conversationId, keyVersion)];
  }

  static Future<({String ciphertextB64, String nonceB64, int keyVersion})>
  encryptMsgForConv(String conversationId, String plaintext) async {
    final keyVersion = getCurrVersion(conversationId);
    if (keyVersion == null) {
      throw Exception('Kc nije ucitan za konverzaciju');
    }
    final kc = getKc(conversationId, keyVersion);
    if (kc == null) {
      throw Exception('Kc nije u kešu');
    }

    final aes = AesGcm.with256bits();
    final nonce = _randBytes(12);
    final aad = utf8.encode('msg|$conversationId|v$keyVersion');

    final secret = SecretKey(kc);
    final box = await aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secret,
      nonce: nonce,
      aad: aad,
    );

    final combined = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]); // ct||tag
    return (
    ciphertextB64: base64Encode(combined),
    nonceB64: base64Encode(nonce),
    keyVersion: keyVersion
    );
  }

  static Future<String> decryptMsgForConv({
    required String conversationId,
    required int keyVersion,
    required String ciphertextB64,
    required String nonceB64,
  }) async {
    var kc = getKc(conversationId, keyVersion);
    if (kc == null) {
      await ensKcForConv(conversationId);
      kc = getKc(conversationId, keyVersion);
    }
    if (kc == null) {
      throw Exception('Kc nije dostupan');
    }

    final bytes = base64Decode(ciphertextB64);
    const tagLen = 16;
    if (bytes.length < tagLen) {
      throw Exception('ciphertext prekratak');
    }
    final ct = bytes.sublist(0, bytes.length - tagLen);
    final mac = Mac(bytes.sublist(bytes.length - tagLen));
    final nonce = base64Decode(nonceB64);
    final aad = utf8.encode('msg|$conversationId|v$keyVersion');

    final aes = AesGcm.with256bits();
    final clear = await aes.decrypt(
      SecretBox(ct, nonce: nonce, mac: mac),
      secretKey: SecretKey(kc),
      aad: aad,
    );
    return utf8.decode(clear);
  }


}
