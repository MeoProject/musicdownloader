import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

final eapiKey = 'e82ckenh8dichen8';

Uint8List aesEncrypt(
  Uint8List buffer,
  String mode,
  Uint8List key,
  Uint8List iv,
) {
  final encrypter = Encrypter(AES(
    Key(key),
    mode: mode == 'aes-128-cbc' ? AESMode.cbc : AESMode.ecb,
    padding: 'PKCS7',
  ));

  return encrypter.encryptBytes(buffer, iv: IV(iv)).bytes;
}

List<int> aesDecrypt(
  Uint8List cipherBuffer,
  String mode,
  Uint8List key,
  Uint8List iv,
) {
  final encrypter = Encrypter(AES(
    Key(key),
    mode: mode == 'aes-128-cbc' ? AESMode.cbc : AESMode.ecb,
    padding: 'PKCS7',
  ));

  return encrypter.decryptBytes(Encrypted(cipherBuffer), iv: IV(iv));
}

Map<String, String> eapi(String url, dynamic object) {
  final text = object is Map ? jsonEncode(object) : object.toString();
  final message = 'nobody${url}use${text}md5forencrypt';
  final digest = md5.convert(utf8.encode(message)).toString();
  final data = '$url-36cd479b6b5-$text-36cd479b6b5-$digest';

  final encrypted = aesEncrypt(
    Uint8List.fromList(utf8.encode(data)),
    'aes-128-ecb',
    Uint8List.fromList(utf8.encode(eapiKey)),
    Uint8List(0),
  );

  return {
    'params': encrypted
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase(),
  };
}

String eapiDecrypt(Uint8List cipherBuffer) {
  final decrypted = aesDecrypt(
    cipherBuffer,
    'aes-128-ecb',
    Uint8List.fromList(utf8.encode(eapiKey)),
    Uint8List(0),
  );

  return utf8.decode(decrypted);
}
