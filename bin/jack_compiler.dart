import 'dart:io';

import 'compilation_engine.dart';
import 'tokenizer.dart';

/// Usage: `dart jack_compiler {source}` where source is an optional path of either a file
/// name of the form `{x}.jack` or the name of a folder containing one or more .jack files.
/// If source is not specified, the program will operate on the current directory.
/// For each `{x}.jack` file, a corresponding `{x}.xml` will be created. The original
/// directory structure will be maintained, and the analyzer will operate recursively.
void main(List<String> arguments) async {
  exitCode = 0;

  // The root directory to operate on.
  Directory? _directory;

  final _filesToTranslate = <File>[];

  void _invalidPath(String path) {
    exitCode = 2;
    print('💩 Invalid file or directory path: "$path"');
  }

  if (arguments.isEmpty) {
    print('No filepath argument, operating on current directory');
    _directory = Directory.current;
  } else {
    // We have an argument, but still need to figure out if it is a file or directory.
    final entityPath = arguments.first;
    final pathSegments = entityPath.split('/');
    // If we have a file...
    if (pathSegments.last.contains('.jack')) {
      // Ensure file exists.
      final file = File(entityPath);
      if (!(await file.exists())) {
        return _invalidPath(entityPath);
      }

      _filesToTranslate.add(file);
    } else {
      _directory = Directory(entityPath);
    }
  }

  // Collect files if operating on directory.
  if (_directory != null) {
    // Ensure directory is valid
    if (!(await _directory.exists())) {
      return _invalidPath(_directory.path);
    }

    print('✅ Gathering *.jack files for the directory: "${_directory.path}"');

    final files = _directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('.jack'));

    void addFile(File f) => _filesToTranslate.add(f);
    files.forEach(addFile);
  }

  // Final check to ensure we gathered files.
  if (_filesToTranslate.isEmpty) {
    print('💩 No *.jack files found to translate.');
    exitCode = 2;
    return;
  }

  for (final file in _filesToTranslate) {
    final pathSegments = file.path.split('/');
    final lastPathSegment = pathSegments.removeLast();
    pathSegments.add(lastPathSegment.replaceFirst(
        '.jack', '.vm', lastPathSegment.length - 5));

    final outputPath = pathSegments.join('/');
    print('Compiling "$outputPath"');

    CompilationEngine(Tokenizer(file), outputPath).compileClass();
  }
}
