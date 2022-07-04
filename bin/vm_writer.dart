import 'dart:io';

abstract class IVMWriter {
  void writePush(MemorySegment segment, int index);
  void writePop(MemorySegment segment, int index);
  void writeArithmetic(Command cmd);
  void writeLabel(String label);
  void writeGoto(String label);
  void writeIf(String label);
  void writeCall(String name, int nArgs);
  void writeFunction(String name, int nVars);
  void writeReturn();
  void close();
}

enum MemorySegment {
  constant,
  argument,
  local,
  statik,
  thiz,
  that,
  pointer,
  temp,
}

extension Value on MemorySegment {
  String value() {
    final asString = toString().replaceFirst(r'MemorySegment.', '');

    // Manually handle values that are reserved words in Dart.
    switch (asString) {
      case 'statik':
        return 'static';
      case 'thiz':
        return 'this';
      default:
        return asString;
    }
  }
}

enum Command {
  add,
  sub,
  neg,
  eq,
  gt,
  lt,
  and,
  or,
  not,
}

extension on Command {
  /// Translates a [Command] into a valid arithmetic-logic operation in the VM
  /// language.
  String value() => toString().replaceFirst(r'Command.', '');
}

class VMWriter implements IVMWriter {
  final RandomAccessFile _raFile;

  VMWriter(String outputPath)
      : _raFile = File(outputPath).openSync(mode: FileMode.write);

  @override
  void close() {
    _raFile.closeSync();
  }

  @override
  void writeArithmetic(Command cmd) {
    _writeLn(cmd.value());
  }

  @override
  void writeCall(String name, int nArgs) {
    _writeLn('call $name $nArgs');
  }

  @override
  void writeFunction(String name, int nVars) {
    _writeLn('function $name $nVars');
  }

  @override
  void writeGoto(String label) {
    _writeLn('goto $label');
  }

  @override
  void writeIf(String label) {
    _writeLn('if-goto $label');
  }

  @override
  void writeLabel(String label) {
    _writeLn('label $label');
  }

  @override
  void writePop(MemorySegment segment, int index) {
    _writeLn('pop ${segment.value()} $index');
  }

  @override
  void writePush(MemorySegment segment, int index) {
    _writeLn('push ${segment.value()} $index');
  }

  @override
  void writeReturn() {
    _writeLn('return');
  }

  /// Writes string to output and appends a newline.
  void _writeLn(String str) {
    _raFile.writeStringSync(str + '\n');
  }
}
