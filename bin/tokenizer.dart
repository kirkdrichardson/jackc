import 'dart:io';

import 'constants.dart';

abstract class ITokenizer {
  /// Are there more tokens in the input?
  bool hasMoreTokens();

  /// Gets the next token from the input, and makes it the current token.
  /// This method should be called only if [hasMoreTokens] is true.
  /// Initially there is no current token.
  void advance();

  /// Returns the [TokenType] of the current token, as a constant.
  TokenType tokenType();

  /// Returns the [Keyword] which is the current token, as a constant.
  /// This method should be called only if [tokenType] is a [TokenType.keyword].
  Keyword keyword();

  /// Returns the character which is the current token.
  /// Should be called only if [tokenType] is a [TokenType.symbol].
  String symbol();

  /// Returns the string which is the current token.
  /// Should be callsed only if [tokenType] is a [TokenType.identifier].
  String identifier();

  /// Returns the integer value of the current token.
  /// Should be callsed only if [tokenType] is a [TokenType.intConst].
  int intVal();

  /// Returns the string value of the current token, whithout the opening and closing quotes.
  /// Should be callsed only if [tokenType] is a [TokenType.stringConst].
  String stringVal();
}

class Tokenizer implements ITokenizer {
  final String _fileContents;

  /// Opens the input .jack file and gets ready to tokenize it
  Tokenizer(File f) : _fileContents = f.readAsStringSync();

  @override
  void advance() {
    // TODO: implement advance

    print(_fileContents);
  }

  @override
  bool hasMoreTokens() {
    // TODO: implement hasMoreTokens
    throw UnimplementedError();
  }

  @override
  String identifier() {
    // TODO: implement identifier
    throw UnimplementedError();
  }

  @override
  int intVal() {
    // TODO: implement intVal
    throw UnimplementedError();
  }

  @override
  Keyword keyword() {
    // TODO: implement keyword
    throw UnimplementedError();
  }

  @override
  String stringVal() {
    // TODO: implement stringVal
    throw UnimplementedError();
  }

  @override
  String symbol() {
    // TODO: implement symbol
    throw UnimplementedError();
  }

  @override
  TokenType tokenType() {
    // TODO: implement tokenType
    throw UnimplementedError();
  }
}
