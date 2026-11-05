import 'dart:io';
import 'dart:typed_data';

class FileSystemClient {
  // ============
  // File
  // ============

  bool fileExists(String path) {
    return File(path).existsSync();
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

  Set<String> listFilesSync(String path) {
    return Directory(path).listSync().map((e) => e.path).toSet();
  }
}
