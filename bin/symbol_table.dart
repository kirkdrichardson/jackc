abstract class ISymbolTable {
  /// Empties the symbol table, and resets the four indices to 0.
  /// Should be called when starting to compile a subroutine declaration.
  void reset();

  /// Defines (adds to the table) a new variable of the given name, type, and
  /// kind. Assigns to it the index value of that kind and adds
  /// 1 to the index.
  void define(String name, String type, String kind);

  // /// Returns the number of variables of the given kind already defined
  // /// in the table.
  // int varCount(String kind);

  /// Returns the kind of the named identifier (STATIC, FIELD, ARG, VAR, NONE)
  String kindOf(String name);

  /// Returns the type of the named variable.
  String typeOf(String name);

  /// Returns the index of the named variable, or -1 if not found.
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
  /// A variable name to metadata map.
  final Map<String, _VarInfo> _table = {};

  /// Tracks counts of variables by kind.
  final _countForKind = {
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

    final prevCount = _countForKind[kind];
    if (prevCount == null) {
      throw Exception('Invalid kind $kind for variable $name');
    }

    _table[name] = _VarInfo(
      name: name,
      type: type,
      kind: kind,
      index: prevCount, // Index is 0-based, lags count by 1.
    );

    _countForKind[kind] = prevCount + 1;
  }

  @override
  int indexOf(String name) => _table[name]?.index ?? -1;

  @override
  String kindOf(String name) {
    final v = _getVarOrThrow(name);
    return v.kind;
  }

  @override
  void reset() {
    _table.clear();
    resetIndex(k) => _countForKind[k] = 0;
    _countForKind.keys.forEach(resetIndex);
  }

  @override
  String typeOf(String name) {
    final v = _getVarOrThrow(name);
    return v.type;
  }

  @override
  String toString() {
    final b = StringBuffer();
    void writeValue(_VarInfo e) {
      b.writeln(
          '{name: ${e.name}, kind: ${e.kind}, type: ${e.type}, index: ${e.index}');
    }

    _table.values.forEach(writeValue);
    return b.toString();
  }

  // @override
  // int varCount(String kind) => _countForKind[kind] ?? -1;

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
