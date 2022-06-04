import 'constants.dart';

abstract class ISymbolTable {
  /// Empties the symbol table, and resets the four indices to 0.
  /// Should be called when starting to compile a subroutine declaration.
  void reset();

  /// Defines (adds to the table) a new variable of the given name, type, and
  /// kind. Assigns to it the index value of that kind and adds
  /// 1 to the index.
  void define(String name, String type, String kind);

  /// Returns the number of variables of the given kind already defined
  /// in the table.
  int varCount(String kind);

  /// Returns the kind of the named identifier (STATIC, FIELD, ARG, VAR, NONE)
  String kindOf(String name);

  /// Returns the type of the named variable.
  String typeOf(String name);

  /// Returns the index of the named variable.
  int indexOf(String name);
}

class SymbolTable implements ISymbolTable {
  @override
  void define(String name, String type, String kind) {
    // TODO: implement define
  }

  @override
  int indexOf(String name) {
    // TODO: implement indexOf
    throw UnimplementedError();
  }

  @override
  String kindOf(String name) {
    // TODO: implement kindOf
    throw UnimplementedError();
  }

  @override
  void reset() {
    // TODO: implement reset
  }

  @override
  String typeOf(String name) {
    // TODO: implement typeOf
    throw UnimplementedError();
  }

  @override
  int varCount(String kind) {
    // TODO: implement varCount
    throw UnimplementedError();
  }
}
