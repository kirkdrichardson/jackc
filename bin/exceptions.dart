import 'constants.dart';

class InvalidTokenTypeException implements Exception {
  TokenType? validType;
  TokenType invalidType;
  InvalidTokenTypeException(this.validType, this.invalidType);

  @override
  String toString() =>
      'Cannot perform operations for  $invalidType when $validType is the current token';
}

abstract class CompilationException implements Exception {
  final String _message;

  CompilationException(this._message);

  @override
  String toString() => _message;
}

class InvalidTypeException extends CompilationException {
  InvalidTypeException(String currentToken)
      : super('Expected a valid type, but got $currentToken');
}

class InvalidIdentifierException extends CompilationException {
  InvalidIdentifierException(String currentToken)
      : super('Expected a valid identifier, but got $currentToken');
}
