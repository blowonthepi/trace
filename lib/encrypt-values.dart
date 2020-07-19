import 'package:encrypt/encrypt.dart';

class EncVals {
  final key = Key.fromLength(32);
  final iv = IV.fromLength(16);
}