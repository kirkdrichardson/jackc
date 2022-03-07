import 'dart:io';

import 'constants.dart';
import 'exceptions.dart';
import 'tokenizer.dart';

abstract class ICompilationEngine {
  /// Compiles a complete class.
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
  final Tokenizer tokenizer;
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
    if (tokenizer.tokenType() != TokenType.identifier) {
      throw Exception(
          'Expected class var declaration but got "$_currentToken"');
    }
    // Write the class name.
    _writeXMLToken();
    _currentToken = tokenizer.advance();
    _process('{');

    // TODO: HANDLE 0 OR MORE INSTANCES OF THIS.
    compileClassVarDec();

    // TODO: HANDLE 0 OR MORE INSTANCES OF THIS.
    compileSubroutine();
    _process('}');
    _raFile.closeSync();
  }

  @override
  void compileClassVarDec() {
    // TODO: implement compileClassVarDec

    String? tokenToProcess;

    if (_currentToken == 'field') {
      tokenToProcess = 'field';
    } else if (_currentToken == 'static') {
      tokenToProcess = 'static';
    } else {
      // Do nothing if we don't have a class var declaration.
      return;
    }

    _writeLn('<classVarDec>');
    _process(tokenToProcess);

    if (tokenType == TokenType.identifier) {
      // Here we _assume_ an identifier is a valid class name.
      _process(_currentToken);
    } else if (tokenType == TokenType.keyword) {
      if (isType(_currentToken)) {
        _process(_currentToken);
      } else {
        throw InvalidTypeException(_currentToken);
      }
    }

    if (tokenType == TokenType.identifier) {
      _process(_currentToken);
    } else {
      throw InvalidIdentifierException(_currentToken);
    }

    // TODO: SUPPORT MULTIPLE INLINE VAR DECLARATIONS

    _process(';');
    _writeLn('</classVarDec>');
  }

  @override
  void compileDo() {
    // TODO: implement compileDo
  }

  @override
  void compileExpression() {
    // TODO: implement compileExpression
  }

  @override
  int compileExpressionList() {
    // TODO: implement compileExpressionList
    throw UnimplementedError();
  }

  @override
  void compileIf() {
    // TODO: implement compileIf
  }

  @override
  void compileLet() {
    // TODO: implement compileLet
  }

  @override
  void compileParameterList() {
    // TODO: implement compileParameterList
  }

  @override
  void compileReturn() {
    // TODO: implement compileReturn
  }

  @override
  void compileStatements() {
    // TODO: implement compileStatements
  }

  @override
  void compileSubroutine() {
    // TODO: implement compileSubroutine
    _writeLn('TODO - compileClassVarDec');
  }

  @override
  void compileSubroutineBody() {
    // TODO: implement compileSubroutineBody
  }

  @override
  void compileTerm() {
    // TODO: implement compileTerm
  }

  @override
  void compileVarDec() {
    // TODO: implement compileVarDec
  }

  @override
  void compileWhile() {
    // TODO: implement compileWhile
  }

//******************************************************************************
// Utilities
//******************************************************************************

  _process(String token) {
    if (_currentToken == token) {
      _writeXMLToken();
    } else {
      throw Exception('Syntax error - expected $token but got $_currentToken');
    }

    _currentToken = tokenizer.advance();
  }

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

  void _writeLn(String str) {
    _raFile.writeStringSync(str + '\n');
  }
}
