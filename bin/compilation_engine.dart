import 'dart:io';

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

class CompilationEngine {
  final RandomAccessFile _raFile;

  /// Opens the input .jack file and gets ready to tokenize it
  CompilationEngine(File f) : _raFile = f.openSync(mode: FileMode.write);
}
