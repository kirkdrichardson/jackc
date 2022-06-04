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

class _VarInfo {
  String name;
  String type;
  String kind;
  int index;
  _VarInfo({
    required this.name,
    required this.type,
    required this.kind,
    required this.index,
  });
}

class SymbolTable implements ISymbolTable {
  final Map<String, _VarInfo> _table = {};
  final _indexOfKind = {
    'static': 0,
    'field': 0,
    'arg': 0,
    'var': 0,
  };

  //////////////////////////////////////////////////////////////////////////////
  ///////////////////////       Public API      ////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  @override
  void define(String name, String type, String kind) {
    // NOTE - currently does not handle duplicate var exceptions.
    // Closest scope will win.

    _table[name] = _VarInfo(
      name: name,
      type: type,
      kind: kind,
      index: varCount(kind),
    );
  }

  @override
  int indexOf(String name) => _table[name]?.index ?? 0;

  @override
  String kindOf(String name) {
    final v = _getVarOrThrow(name);
    return v.kind;
  }

  @override
  void reset() {
    _table.clear();
    resetIndex(k) => _indexOfKind[k] = 0;
    _indexOfKind.keys.forEach(resetIndex);
  }

  @override
  String typeOf(String name) {
    final v = _getVarOrThrow(name);
    return v.type;
  }

  @override
  int varCount(String kind) => _indexOfKind[kind]!;

  //////////////////////////////////////////////////////////////////////////////
  //////////////////       Private Utility      ////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  _VarInfo _getVarOrThrow(String name) {
    final v = _table[name];
    if (v == null) {
      throw Exception('Var $name not found in SymbolTable');
    }

    return v;
  }
}
