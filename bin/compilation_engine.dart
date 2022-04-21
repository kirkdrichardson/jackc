import 'dart:io';

import 'constants.dart';
import 'exceptions.dart';
import 'tokenizer.dart';

// TODO: make all fields private and just expose a compile() method.
abstract class ICompilationEngine {
  /// Compiles a complete class.
  ///
  /// Should be the first and only method called.
  void compileClass();

  /// Compiles a static variable declaration or a field declaration.
  void compileClassVarDec();

  /// Compiles a complete method, function, or constructor.
  void compileSubroutine();

  /// Compiles a (possibly empty) parameter list.
  /// Does not handle the enclosing parentheses tokens ( and ).
  void compileParameterList();

  /// Compiles a subroutine's body.
  void compileSubroutineBody();

  /// Compiles avar declaration.
  void compileVarDec();

  /// Compiles a sequence of statements.
  /// Does not handle the enclosing curly bracket tokens { and }.
  void compileStatements();

  /// Compiles a let statement.
  void compileLet();

  /// Compiles an if statement, possibly with a trailing else clause.
  void compileIf();

  /// Compiles a while statement.
  void compileWhile();

  /// Compiles a do statement.
  void compileDo();

  /// Compiles a return statement.
  void compileReturn();

  /// Compiles an expression.
  void compileExpression();

  /// Compiles a term. If the current token is an identifier the routine
  /// must resolve it into a variable, an array element, or a subroutine
  /// call. A single lookahead token--which may be [, (, .--suffices to
  /// distinguish between the possibilities. Any other token is not part of
  /// this term and should not be advanced over.
  void compileTerm();

  /// Compiles a (possibly empty) command-separated list of expressions.
  /// Returns the number of expressions in the list.
  int compileExpressionList();
}

class CompilationEngine implements ICompilationEngine {
  final ITokenizer tokenizer;
  final RandomAccessFile _raFile;
  String _currentToken;

  TokenType get tokenType => tokenizer.tokenType();

  /// Opens the input .jack file and gets ready to tokenize it
  CompilationEngine(this.tokenizer, File outputFile)
      : _raFile = outputFile.openSync(mode: FileMode.write),
        _currentToken = tokenizer.advance();

  @override
  void compileClass() {
    _writeLn('<class>');
    _process('class');
    if (tokenType != TokenType.identifier) {
      throw InvalidIdentifierException(
          'Expected class var declaration but got "$_currentToken"');
    }

    // Write the class name.
    _writeXMLToken();
    _currentToken = tokenizer.advance();
    _process('{');

    do {
      compileClassVarDec();
    } while (_currentToken == 'field' || _currentToken == 'static');

    do {
      compileSubroutine();
    } while (
        _selectTokenToProcess(['constructor', 'function', 'method']) != null);
    _process('}', advanceToken: false);
    _writeLn('</class>');
    _raFile.closeSync();
  }

  @override
  void compileClassVarDec() {
    final tokenToProcess = _selectTokenToProcess(['field', 'static']);
    if (tokenToProcess == null) {
      return;
    }
    _writeLn('<classVarDec>');
    _processVarDec(tokenToProcess);
    _writeLn('</classVarDec>');
  }

  @override
  void compileDo() {
    _writeLn('<doStatement>');
    _process('do');
    _compileTerm();
    _process(';');
    _writeLn('</doStatement>');
  }

  @override
  void compileExpression() {
    _writeLn('<expression>');

    var count = 0;

    do {
      if (count > 0 && operators.containsKey(_currentToken)) {
        _process(_currentToken);
      }
      compileTerm();
      count++;
    } while (operators.containsKey(_currentToken));

    _writeLn('</expression>');
  }

  @override
  int compileExpressionList() {
    var count = 0;
    _writeLn('<expressionList>');
    if (_currentToken != ')') {
      do {
        if (_currentToken == ',') {
          _process(',');
        }
        compileExpression();
      } while (_currentToken == ',');
    }
    _writeLn('</expressionList>');
    return count;
  }

  @override
  void compileIf() {
    _writeLn('<ifStatement>');
    _process('if');
    _process('(');
    compileExpression();
    _process(')');
    _process('{');
    compileStatements();
    _process('}');

    if (_currentToken == 'else') {
      _process('else');
      _process('{');
      compileStatements();
      _process('}');
    }
    _writeLn('</ifStatement>');
  }

  @override
  void compileLet() {
    _writeLn('<letStatement>');
    _process('let');
    _processIdentifier();
    if (_currentToken == '[') {
      _process('[');
      compileExpression();
      _process(']');
    }
    _process('=');
    compileExpression();
    _process(';');
    _writeLn('</letStatement>');
  }

  @override
  void compileParameterList() {
    _writeLn('<parameterList>');
    while (_currentToken != ')') {
      _processType();
      _processIdentifier();
      if (_currentToken == ',') {
        _process(',');
      }
    }
    _writeLn('</parameterList>');
  }

  @override
  void compileReturn() {
    _writeLn('<returnStatement>');
    _process('return');
    if (_currentToken != ';') {
      compileExpression();
    }
    _process(';');
    _writeLn('</returnStatement>');
  }

  @override
  void compileStatements() {
    _writeLn('<statements>');
    final statementTokens = ['let', 'if', 'while', 'do', 'return'];

    var tokenToProcess = _selectTokenToProcess(statementTokens);
    while (tokenToProcess != null) {
      switch (tokenToProcess) {
        case 'let':
          compileLet();
          break;
        case 'if':
          compileIf();
          break;
        case 'while':
          compileWhile();
          break;
        case 'do':
          compileDo();
          break;
        case 'return':
          compileReturn();
          break;
      }
      tokenToProcess = _selectTokenToProcess(statementTokens);
    }
    _writeLn('</statements>');
  }

  @override
  void compileSubroutine() {
    final tokenToProcess =
        _selectTokenToProcess(['constructor', 'function', 'method']);
    if (tokenToProcess == null) {
      return;
    }

    _writeLn('<subroutineDec>');
    _process(tokenToProcess);

    if (_currentToken == 'void') {
      _process(_currentToken);
    } else {
      _processType();
    }

    _processIdentifier();
    _process('(');
    compileParameterList();
    _process(')');
    compileSubroutineBody();
    _writeLn('</subroutineDec>');
  }

  @override
  void compileSubroutineBody() {
    _writeLn('<subroutineBody>');
    _process('{');
    while (_currentToken == 'var') {
      compileVarDec();
    }
    compileStatements();
    _process('}');
    _writeLn('</subroutineBody>');
  }

  // term: integerConstant | stringConstant | keywordConstant | varName |
  // varName'[' expression ']' | '(' expression ')' | (unaryOp term) | subroutineCall
  @override
  void compileTerm() {
    _writeLn('<term>');
    _compileTerm();
    _writeLn('</term>');
  }

  void _compileTerm() {
    final token = _currentToken;
    final type = tokenizer.tokenType();

    // If we have a keyword, make sure it is a keyword constant.
    if (type == TokenType.keyword && !keywordConstants.containsKey(token)) {
      throw InvalidKeywordConstantException(token);
    }

    // Process top-level types that don't require any additional logic.
    if (type == TokenType.intConst ||
        type == TokenType.stringConst ||
        type == TokenType.keyword) {
      _process(token);
    }

    if (unaryOp.containsKey(token)) {
      _process(token);
      compileTerm();
    }

    if (token == '(') {
      _process('(');
      compileExpression();
      _process(')');
    }

    if (type == TokenType.identifier) {
      _processIdentifier();
      final nextToken = _currentToken;

      switch (nextToken) {
        case '[':
          _process('[');
          compileExpression();
          _process(']');
          break;
        case '(':
          _process(nextToken);
          compileExpressionList();
          _process(')');
          break;
        case '.':
          _process(nextToken);
          _processIdentifier();
          _process('(');
          compileExpressionList();
          _process(')');
          break;
        default: // Do nothing
      }
      // todo - subroutineCall
    }
  }

  @override
  void compileVarDec() {
    _writeLn('<varDec>');
    _processVarDec('var');
    _writeLn('</varDec>');
  }

  @override
  void compileWhile() {
    _writeLn('<whileStatement>');
    _process('while');
    _process('(');
    compileExpression();
    _process(')');
    _process('{');
    compileStatements();
    _process('}');
    _writeLn('</whileStatement>');
  }

//******************************************************************************
// Utilities
//******************************************************************************

  /// General process to write a token under one of the top-level types and
  /// advance the tokenizer.
  _process(String token, {bool advanceToken = true}) {
    if (_currentToken == token) {
      _writeXMLToken();
    } else {
      throw SyntaxError(token, _currentToken);
    }

    if (advanceToken) {
      _currentToken = tokenizer.advance();
    }
  }

  /// Calls the [_process] method if we have identifier, otherwise throws.
  _processIdentifier() {
    if (tokenType == TokenType.identifier) {
      _process(_currentToken);
    } else {
      throw InvalidIdentifierException(_currentToken);
    }
  }

  /// Processes multiple inline var declarations for class and local vars, where
  /// [type] is the type of var declaration, e.g "field", "var", "static".
  _processVarDec(String type) {
    _process(type);
    _processType();
    _processIdentifier();

    // Support multiple inline var declarations, such as "field int foo, bar;"
    bool hasAdditionalVars() => _currentToken == ',';
    while (hasAdditionalVars()) {
      _process(_currentToken);
      _processIdentifier();
    }
    _process(';');
  }

  /// Processes the current type or throws an exception if  [_currentToken] is
  /// not a valid type.
  void _processType() {
    if (_isType()) {
      _process(_currentToken);
    } else {
      throw InvalidTypeException(_currentToken);
    }
  }

  /// A utility to determine if the [_currentToken] is a valid type.
  ///
  /// Note that if the [_currentToken] is a [TokenType.identifier], it is assumed
  /// that it is a valid class name.
  bool _isType() =>
      (tokenType == TokenType.identifier) ||
      (tokenType == TokenType.keyword && types.contains(_currentToken));

  /// From a list of valid tokens, returns the token to process, or null if
  /// none were valid.
  String? _selectTokenToProcess(List<String> validTokens) {
    for (final token in validTokens) {
      if (_currentToken == token) {
        return token;
      }
    }

    return null;
  }

  /// Top-level tokens. Every symbol falls under one of these token categories.
  void _writeXMLToken() {
    final currentToken = tokenizer.tokenType();

    String xmlOutput;

    switch (currentToken) {
      case TokenType.identifier:
        xmlOutput = '<identifier> ${tokenizer.identifier()} </identifier>';
        break;
      case TokenType.intConst:
        xmlOutput =
            '<integerConstant> ${tokenizer.intVal()} </integerConstant>';
        break;
      case TokenType.keyword:
        // todo - we could probably have tokenizer.keyword return the value directly
        xmlOutput = '<keyword> ${tokenizer.keyword().value()} </keyword>';
        break;
      case TokenType.stringConst:
        xmlOutput =
            '<stringConstant> ${tokenizer.stringVal()} </stringConstant>';
        break;
      case TokenType.symbol:
        final xmlSymbol =
            specialSymbols[tokenizer.symbol()] ?? tokenizer.symbol();
        xmlOutput = '<symbol> $xmlSymbol </symbol>';
        break;
      default:
        throw Exception('Unknown token type: $currentToken');
    }

    _writeLn(xmlOutput);
  }

  /// Writes string to output and appends a newline.
  void _writeLn(String str) {
    _raFile.writeStringSync(str + '\n');
  }
}
