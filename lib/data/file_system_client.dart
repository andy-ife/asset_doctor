import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Simple wrapper around dart:io
class FileSystemClient {
  const FileSystemClient({required this.projectRoot});
  final String projectRoot;

  // ============
  // File
  // ============

  bool fileExists(String path) {
    return File(path).existsSync();
  }

  // syntax sugar
  bool isFile(String path) {
    return fileExists(path);
  }

  String readAsString(String path) {
    return File(path).readAsStringSync();
  }

  Uint8List readAsBytes(String path) {
    return File(path).readAsBytesSync();
  }

  int lengthSync(String path) {
    return File(path).lengthSync();
  }

  Future<int> length(String path) {
    return File(path).length();
  }

  void delete(String path) {
    return File(path).deleteSync();
  }

  // ============
  // Directory
  // ============

  bool directoryExists(String path) {
    return Directory(path).existsSync();
  }

  bool isDirectory(String path) {
    return directoryExists(path);
  }

  Set<String> listFilesSync(String path) {
    return Directory(path).listSync(recursive: true).map((e) => e.path).toSet();
  }

  List<String> getFilesRecursivelyRelative(String dirPath) {
    final files = <String>[];
    if (!directoryExists(dirPath)) return files;
    try {
      for (var entity in listFilesSync(dirPath)) {
        if (isFile(entity)) {
          files
              .add(p.relative(entity, from: projectRoot).replaceAll('\\', '/'));
        }
      }
    } catch (e) {
      rethrow;
    }
    return files;
  }
}
