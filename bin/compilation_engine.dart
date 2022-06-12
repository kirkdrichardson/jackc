import 'dart:io';

import 'constants.dart';
import 'exceptions.dart';
import 'symbol_table.dart';
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

  /// Name of the class being compiled. Used to providing this argument.
  String? _currentClassName;

  /// Name of the subroutine being compiled.
  String? _currentSubroutineName;

  /// Collects field and static variables for the class being compiled.
  final ISymbolTable _classTable = SymbolTable();

  /// Collects arg and local variables for the subroutine being compiled.
  final ISymbolTable _subroutineTable = SymbolTable();

  TokenType get tokenType => tokenizer.tokenType();

  /// Opens the input .jack file and gets ready to tokenize it
  CompilationEngine(this.tokenizer, File outputFile)
      : _raFile = outputFile.openSync(mode: FileMode.write),
        _currentToken = tokenizer.advance();

  @override
  void compileClass() {
    _verifyToken('class');
    _currentClassName = _currentToken;

    _classTable.reset();
    _subroutineTable.reset();

    _processIdentifier(isDeclaration: true);
    _verifyToken('{');

    do {
      compileClassVarDec();
    } while (_currentToken == 'field' || _currentToken == 'static');

    do {
      compileSubroutine();
    } while (
        _selectTokenToProcess(['constructor', 'function', 'method']) != null);

    _verifyToken('}', advanceToken: false);
    _raFile.closeSync();
  }

  @override
  void compileClassVarDec() {
    final tokenToProcess = _selectTokenToProcess(['field', 'static']);
    if (tokenToProcess == null) {
      return;
    }

    _writeLn('<classVarDec>');
    _processVarDec(tokenToProcess, VarScope.clazz);
    _writeLn('</classVarDec>');
  }

  @override
  void compileDo() {
    _verifyToken('do');
    compileExpression();
    // Calling a subroutine above will have pushed a value to the stack, so
    // we want to discard it.
    _writeLn('pop temp 0');
    _verifyToken(';');
  }

  @override
  void compileExpression() {
    compileTerm();

    while (operators.containsKey(_currentToken)) {
      final operator = _currentToken;
      _advanceToken();
      compileTerm();

      switch (operator) {
        case '+':
          _writeLn('add');
          break;
        case '-':
          _writeLn('subtract');
          break;
        case '*':
          _writeLn('call Math.multiply 2');
          break;
        case '/':
          _writeLn('call Math.divide 2');
          break;
        // case '-':
        //   _writeLn('call Math.multiply 2');
        //   break;
        default:
          throw UnimplementedError('Operator "$operator" not implemented');
      }
    }
  }

  @override
  int compileExpressionList() {
    var count = 0;
    if (_currentToken != ')') {
      do {
        if (_currentToken == ',') {
          _advanceToken();
        }
        compileExpression();
        count++;
      } while (_currentToken == ',');
    }
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
    _processIdentifier(isDeclaration: false);
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
    while (_currentToken != ')') {
      final type = _getTypeOrThrow();
      _advanceToken();

      final argName = _currentToken;
      _subroutineTable.add(argName, type, 'arg');

      _advanceTokenBeyondIdentifier();

      if (_currentToken == ',') {
        _verifyToken(',');
      }
    }
  }

  @override
  void compileReturn() {
    _verifyToken('return');

    if (_currentToken != ';') {
      compileExpression();
    } else {
      // If we have a void return, we need to push a default value to fulfill
      // the function call and return contract.
      _writeLn('push constant 0');
    }
    _verifyToken(';');
    _writeLn('return');
  }

  @override
  void compileStatements() {
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
  }

  @override
  void compileSubroutine() {
    _subroutineTable.reset();

    final subroutineKind =
        _selectTokenToProcess(['constructor', 'function', 'method']);
    if (subroutineKind == null) {
      return;
    }

    // Provide the "this" argument if it is a method.
    if ('method' == subroutineKind) {
      _subroutineTable.add('this', _currentClassName!, 'arg');
    }

    // Advance past subroutine kind.
    _advanceToken();

    // Swallow return type for now.
    String returnType = _currentToken;
    if (returnType != 'void') {
      returnType = _getTypeOrThrow();
    }
    _advanceToken();

    _currentSubroutineName = _currentToken;
    _advanceTokenBeyondIdentifier();

    _writeLn(
        'function $_currentClassName.$_currentSubroutineName ${_subroutineTable.varCount('arg')}');

    _verifyToken('(');
    compileParameterList();
    _verifyToken(')');
    compileSubroutineBody();

    _currentSubroutineName = null;
  }

  @override
  void compileSubroutineBody() {
    _verifyToken('{');
    while (_currentToken == 'var') {
      // todo - convert from xml to vm
      compileVarDec();
    }
    compileStatements();
    _verifyToken('}');
  }

  // term: integerConstant | stringConstant | keywordConstant | varName |
  // varName'[' expression ']' | '(' expression ')' | (unaryOp term) | subroutineCall
  @override
  void compileTerm() {
    final token = _currentToken;
    final type = tokenizer.tokenType();

    // Process top-level types that don't require any additional logic.
    if (type == TokenType.intConst ||
        type == TokenType.stringConst ||
        type == TokenType.keyword) {
      // If we have a keyword, make sure it is a keyword constant.
      if (type == TokenType.keyword && !keywordConstants.containsKey(token)) {
        throw InvalidKeywordConstantException(token);
      }

      _writeLn('push constant $token');
      _advanceToken();
      return;
    }

    if (unaryOp.containsKey(token)) {
      compileTerm();

      if (token == '-') {
        _writeLn('neg');
        _advanceToken();
      } else if (token == '~') {
        throw UnimplementedError();
      }
      return;
    }

    if (token == '(') {
      _verifyToken('(');
      compileExpression();
      _verifyToken(')');
      return;
    }

    if (type == TokenType.identifier) {
      final identifier = _currentToken;
      _advanceTokenBeyondIdentifier();
      final nextToken = _currentToken;

      switch (nextToken) {
        case '[':
          _verifyToken('[');
          compileExpression();
          _verifyToken(']');
          break;
        case '(':
          _verifyToken(nextToken);
          compileExpressionList();
          _verifyToken(')');
          break;
        case '.':
          _advanceToken();
          final subroutineName = _currentToken;
          _advanceTokenBeyondIdentifier();

          _verifyToken('(');
          final argCount = compileExpressionList();
          _verifyToken(')');
          _writeLn('call $identifier.$subroutineName $argCount');
          break;
        default: // Do nothing

      }
    }
  }

  @override
  void compileVarDec() {
    _writeLn('<varDec>');
    _processVarDec('var', VarScope.subroutine);
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

  /// Advances tokenizer and assigns [_currentToken] to new current token.
  void _advanceToken() {
    _currentToken = tokenizer.advance();
  }

  /// Advances tokenizer and assigns [_currentToken] to new current token if
  /// current token is an identifier.
  void _advanceTokenBeyondIdentifier() {
    if (tokenType != TokenType.identifier) {
      throw InvalidIdentifierException(_currentToken);
    }
    _advanceToken();
  }

  /// Throws if expected token doesn't match [_currentToken]. Advances
  /// [_currentToken] when valid unless specified otherwise.
  void _verifyToken(String token, {bool advanceToken = true}) {
    if (_currentToken != token) {
      throw SyntaxError(token, _currentToken);
    }

    if (advanceToken) {
      _advanceToken();
    }
  }

  /// General process to write a token under one of the top-level types and
  /// advance the tokenizer.
  void _process(String token,
      {bool advanceToken = true, _IdentifierType? identifierType}) {
    _verifyToken(token, advanceToken: false);

    final tokenType = tokenizer.tokenType();
    String? xmlOutput;

    switch (tokenType) {
      case TokenType.identifier:
        if (identifierType == null) {
          throw Exception(
              'Must pass _IdentifierType when processing identifier "$_currentToken".');
        }

        final identifier = tokenizer.identifier();

        VarInfo? info;
        info = _subroutineTable.find(identifier);
        info ??= _classTable.find(identifier);

        if (info == null &&
            identifier != _currentClassName &&
            identifier != _currentSubroutineName) {
          throw Exception(
              'Identifier not found in symbol table and is not current class "$identifier"');
        }

        final category = info?.kind ??
            (identifier == _currentClassName ? 'class' : 'subroutine');

        final b = StringBuffer();
        b.writeln('<identifier>');
        b.writeln('<name> $identifier </name>');
        // field, static, var, arg, class, or subroutine
        b.writeln('<category> $category </category>');
        // Only if this is not a class or subroutine
        if (info != null) {
          b.writeln('<index> ${info.index} </index>');
        }
        // declared | used
        b.writeln(
            '<usage> ${identifierType == _IdentifierType.declaration ? "declaration" : "used"} </usage>');

        b.writeln('</identifier>');

        // xmlOutput = b.toString();
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
        throw Exception('Unknown token type: $tokenType');
    }

    if (xmlOutput != null && xmlOutput.trim().isNotEmpty) {
      _writeLn(xmlOutput);
    }

    if (advanceToken) {
      _advanceToken();
    }
  }

  /// Calls the [_process] method if we have identifier, otherwise throws.
  void _processIdentifier({required bool isDeclaration}) {
    if (tokenType == TokenType.identifier) {
      _process(_currentToken,
          identifierType: isDeclaration
              ? _IdentifierType.declaration
              : _IdentifierType.usage);
    } else {
      throw InvalidIdentifierException(_currentToken);
    }
  }

  /// Processes multiple inline var declarations for class and local vars, where
  /// [kind] is the kind of declaration, i.e. "field", "var", "static", "arg".
  void _processVarDec(String kind, VarScope scope) {
    _process(kind);

    // We need to save the type in order to
    //    1. add it to the relevant symbol table, and
    //    2. reference it again in the case of multiline variable declarations
    //
    // Example:
    //    field int i, j;
    // Here, we need both the kind (field) and type (j) to add i and j to the
    // _classTable as independent entries.
    final type = _getTypeOrThrow();
    _process(type);

    var varName = _currentToken;
    _addSymbolTableEntry(scope, varName, type, kind);
    _processIdentifier(isDeclaration: true);

    // Support multiple inline var declarations, such as "field int foo, bar;"
    bool hasAdditionalVars() => _currentToken == ',';
    while (hasAdditionalVars()) {
      _process(_currentToken);
      varName = _currentToken;
      _addSymbolTableEntry(scope, varName, type, kind);
      _processIdentifier(isDeclaration: true);
    }
    _process(';');
  }

  void _addSymbolTableEntry(
    VarScope scope,
    String name,
    String type,
    String kind,
  ) {
    if (scope == VarScope.clazz) {
      _classTable.add(name, type, kind);
    } else {
      _subroutineTable.add(name, type, kind);
    }
  }

  /// Processes the current type or throws an exception if  [_currentToken] is
  /// not a valid type.
  void _processType() {
    _process(_getTypeOrThrow(),
        identifierType:
            tokenType == TokenType.identifier ? _IdentifierType.usage : null);
  }

  /// Returns the [_currentToken] if is a valid type.
  String _getTypeOrThrow() {
    if (_isType()) {
      return _currentToken;
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

  /// Writes string to output and appends a newline.
  void _writeLn(String str) {
    _raFile.writeStringSync(str + '\n');
  }
}

/// Only 2 scopes are currently supported: class and subroutine.
enum VarScope { clazz, subroutine }

/// Used when processing an identifier, to indicate whether variable is being
/// declared or used.
enum _IdentifierType {
  declaration,
  usage,
}
