import 'constants.dart';

class InvalidTokenTypeException implements Exception {
  TokenType? validType;
  TokenType invalidType;
  InvalidTokenTypeException(this.validType, this.invalidType);

  @override
  String toString() =>
      "Cannot perform operations for  $invalidType when $validType is the current token";
}
