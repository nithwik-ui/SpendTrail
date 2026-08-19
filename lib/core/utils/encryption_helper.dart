import 'dart:convert';

class EncryptionHelper {
  static const String _key = 'spendtrail_secret_key_88';

  // Base64 XOR Encryption
  static String encrypt(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final encrypted = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ _key.codeUnitAt(i % _key.length);
    });
    return base64.encode(encrypted);
  }

  // Base64 XOR Decryption
  static String decrypt(String ciphertext) {
    final bytes = base64.decode(ciphertext);
    final decrypted = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ _key.codeUnitAt(i % _key.length);
    });
    return utf8.decode(decrypted);
  }
}
