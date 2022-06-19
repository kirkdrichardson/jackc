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

  void tempRemove(String s);
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
    // TODO: implement writeArithmetic
  }

  @override
  void writeCall(String name, int nArgs) {
    // TODO: implement writeCall
  }

  @override
  void writeFunction(String name, int nVars) {
    // TODO: implement writeFunction
  }

  @override
  void writeGoto(String label) {
    // TODO: implement writeGoto
  }

  @override
  void writeIf(String label) {
    // TODO: implement writeIf
  }

  @override
  void writeLabel(String label) {
    // TODO: implement writeLabel
  }

  @override
  void writePop(MemorySegment segment, int index) {
    // TODO: implement writePop
  }

  @override
  void writePush(MemorySegment segment, int index) {
    // TODO: implement writePush
  }

  @override
  void writeReturn() {
    // TODO: implement writeReturn
  }

  /// todo - remove this once transitioned off of xml output
  @override
  void tempRemove(String str) {
    _writeLn(str);
  }

  /// Writes string to output and appends a newline.
  void _writeLn(String str) {
    _raFile.writeStringSync(str + '\n');
  }
}
