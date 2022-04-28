import 'dart:io';

import 'constants.dart';
import 'exceptions.dart';

abstract class ITokenizer {
  /// Are there more tokens in the input?
  bool hasMoreTokens();

  /// Returns the next token from the input, and makes it the current token.
  ///
  /// This method should be called only if [hasMoreTokens] is true.
  /// Initially there is no current token.
  String advance();

  /// Returns the [TokenType] of the current token, as a constant.
  TokenType tokenType();

  /// Returns the [Keyword] which is the current token, as a constant.
  ///
  /// This method should be called only if [tokenType] is a [TokenType.keyword].
  Keyword keyword();

  /// Returns the character which is the current token.
  ///
  /// Should be called only if [tokenType] is a [TokenType.symbol].
  String symbol();

  /// Returns the string which is the current token.
  ///
  /// Should be called only if [tokenType] is a [TokenType.identifier].
  String identifier();

  /// Returns the integer value of the current token.
  ///
  /// Should be called only if [tokenType] is a [TokenType.intConst].
  int intVal();

  /// Returns the string value of the current token, without the opening and
  /// closing quotes.
  ///
  /// Should be called only if [tokenType] is a [TokenType.stringConst].
  String stringVal();
}

class Tokenizer implements ITokenizer {
  final String _fileContents;

  /// The current token type
  TokenType? _currentTokenType;

  /// The current token
  String? _currentToken;

  /// The current index of `_fileContents`, set to the start of `currentToken`
  int _index = 0;

  /// Opens the input .jack file and gets ready to tokenize it
  Tokenizer(File f) : _fileContents = f.readAsStringSync();

  // todo - consider returning boolean if advanced and making hasMoreTokens a
  // a private method, or fold it into the advance method
  @override
  String advance() {
    if (hasMoreTokens()) {
      final char = _fileContents[_index];

      if (symbols.containsKey(char)) {
        _currentTokenType = TokenType.symbol;
        _currentToken = _fileContents[_index];
        return _currentToken!;
      }

      if (int.tryParse(char) != null) {
        _currentTokenType = TokenType.intConst;
        _currentToken = _intConstMatcherRegEx
            .firstMatch(_fileContents.substring(_index))!
            .group(0);
        return _currentToken!;
      }

      final keywordMatch =
          _keywordMatcherRegEx.firstMatch(_fileContents.substring(_index));
      if (keywordMatch != null) {
        _currentTokenType = TokenType.keyword;
        _currentToken = keywordMatch.group(0);
        return _currentToken!;
      }

      final stringMatch = _getFirstMatch(stringMatcherRegEx);
      if (stringMatch != null) {
        _currentTokenType = TokenType.stringConst;
        _currentToken = stringMatch.group(0);
        return _currentToken!;
      }

      final identifierMatch = _getFirstMatch(_identifierMatcherRegEx);
      if (identifierMatch != null) {
        _currentTokenType = TokenType.identifier;
        _currentToken = identifierMatch.group(0);
        return _currentToken!;
      }

      throw Exception('Unmatched character: $char');
    } else {
      throw Exception('No tokens remaining. Cannot advance');
    }
  }

  // todo - reconsider this operation having the side effect of clearing the current token.
  // Or, perhaps, make this method private and have the advance function return a bool

  /// Returns true if more tokens are present, clears the current token, and
  /// advances beyond any non-sematic whitespace.
  @override
  bool hasMoreTokens() {
    // Move past and clear the current token if defined.
    if (_currentToken != null) {
      _index += _currentToken!.length;
      _currentToken = null;
    }

    // Move past any comments or non-semantic whitespace.
    var commentOrWhitespaceMatch = _getFirstMatch(_commentsMatcherRegEx);
    while (commentOrWhitespaceMatch != null &&
        commentOrWhitespaceMatch.start != commentOrWhitespaceMatch.end) {
      _index += commentOrWhitespaceMatch.end;
      commentOrWhitespaceMatch = _getFirstMatch(_commentsMatcherRegEx);
    }

    return _index < _fileContents.length - 1;
  }

  @override
  String identifier() {
    _checkTokenTypeIsCurrent(TokenType.identifier);
    return _currentToken!;
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
    _checkTokenTypeIsCurrent(TokenType.stringConst);
    // Return the literal value, without quotations.
    return _currentToken!.substring(1, _currentToken!.length - 1);
  }

  @override
  String symbol() {
    _checkTokenTypeIsCurrent(TokenType.symbol);
    return _currentToken!;
  }

  @override
  TokenType tokenType() => _currentTokenType!;

  /// Throws [InvalidTokenTypeException] if [type] doesn't equal [_currentTokenType].
  void _checkTokenTypeIsCurrent(TokenType type) {
    if (type != _currentTokenType) {
      throw InvalidTokenTypeException(_currentTokenType, type);
    }
  }

  /// Returns the first match or null for [re] applied to [_fileContents]
  /// beginning at [index].
  RegExpMatch? _getFirstMatch(RegExp re) =>
      re.firstMatch(_fileContents.substring(_index));
}

//*****************************************************************************
// Utilities
//*****************************************************************************

// Expression to match doc comments, inline comments, and whitespace.
const _commentsMatcher =
    r'^(\/\*(?:[^\*]|\**[^\*\/])*\*+\/)|((?<!")(?!.*";)\/\/.*)|(\s*)';
final _commentsMatcherRegEx = RegExp(_commentsMatcher, caseSensitive: false);
final _intConstMatcherRegEx = RegExp(r'^\d+');
const _keywordMatcher =
    r'^(class|constructor|function|method|field|static|var|int|char|boolean|void|true|false|null|this|let|do|if|else|while|return)';
final _keywordMatcherRegEx = RegExp(_keywordMatcher, caseSensitive: true);
const _identifierMatcher = r'^[_a-z]+[_a-z0-9]*';
final _identifierMatcherRegEx =
    RegExp(_identifierMatcher, caseSensitive: false);
const _stringMatcher = r'^".*"';
final stringMatcherRegEx = RegExp(_stringMatcher);
