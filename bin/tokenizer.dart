import 'dart:io';

import 'constants.dart';
import 'exceptions.dart';

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
const _commentsMatcher =
    r'(\/\*(?:[^\*]|\**[^\*\/])*\*+\/)|((?<!")(?!.*";)\/\/.*)|(\s*)';
final _commentsMatcherRegEx = RegExp(_commentsMatcher, caseSensitive: false);
final _intConstMatcherRegEx = RegExp(r'\d+');
const _keywordMatcher =
    r'(class|constructor|function|method|field|static|var|int|char|boolean|void|true|false|null|this|let|do|if|else|while|return)';
final _keywordMatcherRegEx = RegExp(_keywordMatcher, caseSensitive: true);

class Tokenizer implements ITokenizer {
  final String _fileContents;

  /// The current token type
  TokenType? _currentTokenType;

  /// The current token
  String? _currentToken;

  /// The current index of `_fileContents`, set to the start of `currentToken`
  int _index = 0;

  RegExpMatch? getFirstMatch(int start) =>
      _commentsMatcherRegEx.firstMatch(_fileContents.substring(start));

  /// Opens the input .jack file and gets ready to tokenize it
  Tokenizer(File f) : _fileContents = f.readAsStringSync();

  @override
  void advance() {
    // Move past and clear the current token if defined.
    if (_currentToken != null) {
      _index += _currentToken!.length;
      _currentToken = null;
    }

    // Move past any comments or non-semantic whitespace.
    var commentOrWhitespaceMatch = getFirstMatch(_index);
    while (commentOrWhitespaceMatch != null &&
        commentOrWhitespaceMatch.start != commentOrWhitespaceMatch.end) {
      // print("_fileContents[_index]: ${_fileContents[_index]} ");
      _index += commentOrWhitespaceMatch.end;
      // print("_index: _index");
      // print("match.start: ${match.start}");
      // print("match.end: ${match.end}");
      commentOrWhitespaceMatch = getFirstMatch(_index);
    }

    // If there are additional tokens, parse them.
    if (hasMoreTokens()) {
      final char = _fileContents[_index];

      if (symbols.containsKey(char)) {
        _currentTokenType = TokenType.symbol;
        _currentToken = _fileContents[_index];
        return;
      }

      if (int.tryParse(char) != null) {
        _currentTokenType = TokenType.intConst;
        _currentToken = _intConstMatcherRegEx
            .firstMatch(_fileContents.substring(_index))!
            .group(0);
      }

      final keywordMatch =
          _keywordMatcherRegEx.firstMatch(_fileContents.substring(_index));
      if (keywordMatch != null) {
        _currentTokenType = TokenType.keyword;
        _currentToken = keywordMatch.group(0);
      }

      // print(_currentTokenType);
      // print(_currentToken);
    } else {
      throw Exception('No tokens remaining. Cannot advance');
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

  void _checkTokenTypeIsCurrent(TokenType type) {
    if (type != _currentTokenType) {
      throw InvalidTokenTypeException(_currentTokenType, type);
    }
  }

  @override
  int intVal() {
    _checkTokenTypeIsCurrent(TokenType.intConst);
    return int.parse(_currentToken!);
  }

  @override
  Keyword keyword() {
    _checkTokenTypeIsCurrent(TokenType.keyword);
    return getKeywordFromString(Keyword.values, _currentToken!);
  }

  @override
  String stringVal() {
    // TODO: implement stringVal
    throw UnimplementedError();
  }

  @override
  String symbol() {
    _checkTokenTypeIsCurrent(TokenType.symbol);
    return _currentToken!;
  }

  @override
  TokenType tokenType() => _currentTokenType!;
}
