import 'package:encrypt/encrypt.dart';

// Encryption tool
final encrypter = Encrypter(AES(EncVals().key));
class EncVals {
  final key = Key.fromLength(32);
  final iv = IV.fromLength(16);
}