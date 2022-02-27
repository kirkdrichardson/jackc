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

// Expression to match doc comments, inline comments, and whitespace.
const _exp = r'(\/\*(?:[^\*]|\**[^\*\/])*\*+\/)|((?<!")(?!.*";)\/\/.*)|(\s*)';
final _regExp = RegExp(_exp, caseSensitive: false, multiLine: false);

class Tokenizer implements ITokenizer {
  final String _fileContents;

  /// The current token, beginning at _index
  TokenType? _currentToken;

  /// The current index of `_fileContents`.
  int _index = 0;

  RegExpMatch? getFirstMatch(int start) =>
      _regExp.firstMatch(_fileContents.substring(start));

  /// Opens the input .jack file and gets ready to tokenize it
  Tokenizer(File f) : _fileContents = f.readAsStringSync();

  @override
  void advance() {
    if (hasMoreTokens()) {
      // Move the index until we are at the next token
      var match = getFirstMatch(_index);
      while (match != null && match.start != match.end) {
        // print("_fileContents[_index]: ${_fileContents[_index]} ");
        _index += match.end;
        // print("_index: _index");
        // print("match.start: ${match.start}");
        // print("match.end: ${match.end}");
        match = getFirstMatch(_index);
      }
    }
  }

  @override
  // todo - this should probably look ahead so as to not count whitespace
  bool hasMoreTokens() => _index < _fileContents.length - 1;

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
