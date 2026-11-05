import 'dart:io';

import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  /// Find all files in a directory
  static Set<String> findAllInDirectory(String projectRoot, Directory dir) {
    final files = <String>{};
    if (!dir.existsSync()) {
      Ui.printWarning('Assets directory not found at ${dir.path}');
      return files;
    }
    try {
      for (var entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          if (!p.basename(entity.path).startsWith('.')) {
            files.add(p
                .relative(entity.path, from: projectRoot)
                .replaceAll('\\', '/'));
          }
        }
      }
    } catch (e) {
      Ui.printError('Error listing files in ${dir.path}: $e');
    }
    if (files.isEmpty) {
      Ui.printWarning(
          'No files found in the assets directory ${dir.path} (Excluding hidden files)');
    } else {
      Ui.printInfo('\nFound ${files.length} files in the assets directory.');
    }
    return files;
  }

  /// Find all files from a set of directories
  static Set<String> findAllInDirectories(
      String projectRoot, List<Directory> directories) {
    final result = <String>{};
    for (var dir in directories) {
      result.addAll(findAllInDirectory(projectRoot, dir));
    }
    return result;
  }

  

  static double calculateTotalFileSize(List<File> files) {
    return files.fold(0, (sum, curFile) {
      return curFile.existsSync() ? sum + curFile.lengthSync() : sum;
    });
  }
}
