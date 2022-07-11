// ignore_for_file: non_constant_identifier_names

import 'constants.dart';
import 'exceptions.dart';
import 'symbol_table.dart';
import 'tokenizer.dart';
import 'vm_writer.dart';

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
  // Suffix for creating unique labels for control-flow statements.
  static int _labelCount = 0;

  final ITokenizer tokenizer;
  String _currentToken;

  final IVMWriter writer;

  /// Name of the class being compiled. Used to providing this argument.
  String? _currentClassName;

  /// Name of the subroutine being compiled.
  String? _currentSubroutineName;

  /// Collects field and static variables for the class being compiled.
  final ISymbolTable _classTable = SymbolTable();

  /// Collects arg and local variables for the subroutine being compiled.
  final ISymbolTable _subroutineTable = SymbolTable();

  TokenType get tokenType => tokenizer.tokenType();

  int labelSuffix() => ++_labelCount;

  /// Opens the input .jack file and gets ready to tokenize it
  CompilationEngine(this.tokenizer, String outputFile)
      : _currentToken = tokenizer.advance(),
        writer = VMWriter(outputFile);

  @override
  void compileClass() {
    _verifyToken('class');
    _currentClassName = _currentToken;

    _classTable.reset();
    _subroutineTable.reset();

    _advanceTokenBeyondIdentifier();
    _verifyToken('{');

    do {
      compileClassVarDec();
    } while (_currentToken == 'field' || _currentToken == 'static');

    do {
      compileSubroutine();
    } while (
        _selectTokenToProcess(['constructor', 'function', 'method']) != null);

    _verifyToken('}', advanceToken: false);
    writer.close();
  }

  @override
  void compileClassVarDec() {
    final tokenToProcess = _selectTokenToProcess(['field', 'static']);
    if (tokenToProcess == null) {
      return;
    }

    _processVarDec(tokenToProcess, VarScope.clazz);
  }

  @override
  void compileDo() {
    _verifyToken('do');
    compileExpression();
    // Calling a subroutine above will have pushed a value to the stack, so
    // we want to discard it.
    writer.writePop(MemorySegment.temp, 0);
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
          writer.writeArithmetic(Command.add);
          break;
        case '-':
          writer.writeArithmetic(Command.sub);
          break;
        case '*':
          writer.writeCall('Math.multiply', 2);
          break;
        case '/':
          writer.writeCall('Math.divide', 2);
          break;
        case '&':
          writer.writeArithmetic(Command.and);
          break;
        case '|':
          writer.writeArithmetic(Command.or);
          break;
        case '<':
          writer.writeArithmetic(Command.lt);
          break;
        case '>':
          writer.writeArithmetic(Command.gt);
          break;
        case '=':
          writer.writeArithmetic(Command.eq);
          break;
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
    _verifyToken('if');
    _verifyToken('(');
    // Evaluate the if condition and negate the value
    compileExpression();
    writer.writeArithmetic(Command.not);

    // Generate the labels we will use to implement branching logic
    final suffix = labelSuffix();
    final L1 = 'IF_START_$suffix';
    final L2 = 'IF_END_$suffix';

    // Conditionally jump to L1
    writer.writeIf(L1);

    _verifyToken(')');
    _verifyToken('{');

    compileStatements();
    _verifyToken('}');

    // If we haven't skipped to L1, we've evaluated the if block and skip to end
    writer.writeGoto(L2);

    // We jump here and conditionally compile the else statement if present.
    writer.writeLabel(L1);

    if (_currentToken == 'else') {
      _verifyToken('else');
      _verifyToken('{');
      compileStatements();
      _verifyToken('}');
    }

    writer.writeLabel(L2);
  }

  @override
  void compileLet() {
    _verifyToken('let');
    final varInfo = _getVarOrThrow(_currentToken);
    _advanceTokenBeyondIdentifier();

    // todo - handle arrays
    if (_currentToken == '[') {
      _verifyToken('[');
      compileExpression();
      _verifyToken(']');
    }
    _verifyToken('=');
    compileExpression();

    final segment = _segmentFromKind(varInfo.kind);

    writer.writePop(segment, varInfo.index);
    _verifyToken(';');
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
      writer.writePush(MemorySegment.constant, 0);
    }
    _verifyToken(';');
    writer.writeReturn();
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

    // We need to compile the parameter list before writing the function.
    _verifyToken('(');
    compileParameterList();
    _verifyToken(')');

    // Before generating any code, we need to compile all the var declarations
    // so we know how many local vars the fn has.
    _verifyToken('{');
    while (_currentToken == 'var') {
      compileVarDec();
    }

    // Now we can reference the symbol table and write the fn declaration
    // with the appropriate number of local vars. This allows the compiler's
    // backend to allocate the appropriate length of the local memory segment.
    writer.writeFunction('$_currentClassName.$_currentSubroutineName',
        _subroutineTable.varCount('var'));

    if ('constructor' == subroutineKind) {
      writer.writePush(MemorySegment.constant, _classTable.varCount('field'));
      writer.writeCall('Memory.alloc', 1);
      writer.writePop(MemorySegment.pointer, 0);
    }

    if (subroutineKind == 'method') {
      // If we have a method, we need to align the THIS pointer to to value of
      // argument 0, which will contain the base address of the object on which
      // the method was called to operate per the method calling contract.
      writer.writePush(MemorySegment.argument, 0);
      writer.writePop(MemorySegment.pointer, 0);
    }

    compileSubroutineBody();

    _currentSubroutineName = null;
  }

  @override
  void compileSubroutineBody() {
    compileStatements();
    _verifyToken('}');
  }

  // term: integerConstant | stringConstant | keywordConstant | varName |
  // varName'[' expression ']' | '(' expression ')' | (unaryOp term) | subroutineCall
  @override
  void compileTerm() {
    final token = _currentToken;
    final type = tokenizer.tokenType();

    if (type == TokenType.intConst) {
      writer.writePush(MemorySegment.constant, int.parse(token));
      _advanceToken();
      return;
    }

    if (type == TokenType.stringConst) {
      final length = token.length;
      // Create the String using the OS.
      writer.writePush(MemorySegment.constant, length);
      writer.writeCall('String.new', 1);

      // Push each char onto the stack and append it to the string.
      for (var i = 0; i < length; i++) {
        writer.writePush(MemorySegment.constant, token.codeUnitAt(i));
        writer.writeCall('String.appendChar', 2);
      }
      _advanceToken();
      return;
    }

    if (type == TokenType.keyword) {
      if (token == 'null' || token == 'false') {
        writer.writePush(MemorySegment.constant, 0);
      } else if (token == 'true') {
        writer.writePush(MemorySegment.constant, 1);
        writer.writeArithmetic(Command.neg);
      } else if (token == 'this') {
        writer.writePush(MemorySegment.pointer, 0);
      } else {
        throw InvalidKeywordConstantException(token);
      }
      _advanceToken();
      return;
    }

    if (unaryOp.containsKey(token)) {
      _advanceToken();
      compileTerm();

      if (token == '-') {
        writer.writeArithmetic(Command.neg);
      } else if (token == '~') {
        writer.writeArithmetic(Command.not);
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
        case '.':
          // First determine if we have a method or function/constructor call.
          final varInfo =
              _subroutineTable.find(identifier) ?? _classTable.find(identifier);
          final isMethod =
              varInfo != null || identifier[0] != identifier[0].toUpperCase();

          String? className;

          if (isMethod) {
            // If varInfo is defined, the call is in the form
            // varName.methodName(exp1...) and we can push the symbol table
            // mapping of varName. Otherwise, it is in the form
            //  methodName(exp1...), and we push the a mapping of the current
            // object.
            if (varInfo != null) {
              writer.writePush(_segmentFromKind(varInfo.kind), varInfo.index);
            } else {
              writer.writePush(MemorySegment.pointer, 0);
            }
            // If we have a method, we must note the [type] of class for when
            // we write the fn call later.
            className = varInfo?.type ?? _currentClassName;
          }

          String subroutineName;
          if (nextToken == '.') {
            // We have either varName.methodCall(...), ClassName.functionName,
            // or ClassName.constructorName(...), so the subroutineName is the
            // next token.
            _advanceToken();
            subroutineName = _currentToken;
            _advanceTokenBeyondIdentifier();
          } else {
            // We have methodCall(...), so the current identifier == methodCall.
            subroutineName = identifier;
          }

          // Compile the parameters.
          _verifyToken('(');
          final argCount = compileExpressionList();
          _verifyToken(')');

          writer.writeCall(
            '${className ?? identifier}.$subroutineName',
            // Methods push the additional "this" arg onto the stack.
            argCount + (isMethod ? 1 : 0),
          );

          break;
        default:
          // Get the value and push it on the stack.
          final info = _getVarOrThrow(identifier);
          writer.writePush(_segmentFromKind(info.kind), info.index);
          break;
      }
    }
  }

  @override
  void compileVarDec() {
    _processVarDec('var', VarScope.subroutine);
  }

  @override
  void compileWhile() {
    _verifyToken('while');
    _verifyToken('(');

    // Generate the labels we will use to implement branching logic
    final suffix = labelSuffix();
    final L1 = 'WHILE_START_$suffix';
    final L2 = 'WHILE_END_$suffix';

    // Write the first label to return to our test condition.
    writer.writeLabel(L1);
    // Push the value of the while(__expression__) onto the stack.
    compileExpression();
    _verifyToken(')');
    _verifyToken('{');

    // NOT the value of the compiled expression on the stack so we know if we
    // should jump over the logic between here and the next label, i.e. the
    // end of the while statement.
    writer.writeArithmetic(Command.not);

    // If !expression
    writer.writeIf(L2);
    compileStatements();
    // Return to evaluate while expression again.
    writer.writeGoto(L1);

    // Anchor our terminating label at the end.
    writer.writeLabel(L2);
    _verifyToken('}');
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

  /// Processes multiple inline var declarations for class and local vars, where
  /// [kind] is the kind of declaration, i.e. "field", "var", "static".
  void _processVarDec(String kind, VarScope scope) {
    // Check that the kind is valid
    final validKinds = ["field", "var", "static"];
    if (!["field", "var", "static"].contains(kind)) {
      throw Exception('Expected one of $validKinds but got $kind');
    }

    _advanceToken();

    // We need to save the type in order to
    //    1. add it to the relevant symbol table, and
    //    2. reference it again in the case of multiline variable declarations
    //
    // Example:
    //    field int i, j;
    // Here, we need both the kind (field) and type (j) to add i and j to the
    // _classTable as independent entries.
    final type = _getTypeOrThrow();
    _advanceToken();

    var varName = _currentToken;
    _addSymbolTableEntry(scope, varName, type, kind);
    _advanceTokenBeyondIdentifier();

    // Support multiple inline var declarations, such as "field int foo, bar;"
    bool hasAdditionalVars() => _currentToken == ',';
    while (hasAdditionalVars()) {
      _advanceToken();
      varName = _currentToken;
      _addSymbolTableEntry(scope, varName, type, kind);
      _advanceTokenBeyondIdentifier();
    }
    _verifyToken(';');
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

  /// Returns the [_currentToken] if is a valid type.
  String _getTypeOrThrow() {
    if (_isType()) {
      return _currentToken;
    } else {
      throw InvalidTypeException(_currentToken);
    }
  }

  /// Finds the [VarInfo] for a given variable name by looking first in the
  /// subroutine symbol table, then the class table. Throws if not found.
  VarInfo _getVarOrThrow(String varName) {
    final varInfo = _subroutineTable.find(varName) ?? _classTable.find(varName);

    if (varInfo == null) {
      throw UndeclaredIdentifierException(varName);
    }

    return varInfo;
  }

  /// A utility to determine if the [_currentToken] is a valid type.
  ///
  /// Note that if the [_currentToken] is a [TokenType.identifier], it is assumed
  /// that it is a valid class name.
  bool _isType() =>
      (tokenType == TokenType.identifier) ||
      (tokenType == TokenType.keyword && types.contains(_currentToken));

  MemorySegment _segmentFromKind(String kind) {
    switch (kind) {
      case 'static':
        return MemorySegment.statik;
      case 'field':
        return MemorySegment.thiz;
      case 'arg':
        return MemorySegment.argument;
      case 'var':
        return MemorySegment.local;
      default:
        throw Exception('Unrecognized kind "$kind". Unable to map mem segment');
    }
  }

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
}

/// Only 2 scopes are currently supported: class and subroutine.
enum VarScope { clazz, subroutine }
