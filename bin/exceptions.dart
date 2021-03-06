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

class InvalidKeywordConstantException extends CompilationException {
  InvalidKeywordConstantException(String currentToken)
      : super('Expected a keyword constant, but got $currentToken');
}

class SyntaxError extends CompilationException {
  SyntaxError(String expected, String actual)
      : super('Syntax Error: expected $expected but got $actual');
}

class UndeclaredIdentifierException extends CompilationException {
  UndeclaredIdentifierException(String identifier)
      : super('Declaration for variable "$identifier" not found');
}
