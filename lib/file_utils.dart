import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  FileUtils({
    required this.projectRoot,
    required this.ignoredDirs,
    FileSystemClient? fs,
    Console? console,
  })  : fs = fs ?? FileSystemClient(projectRoot: projectRoot),
        console = console ?? Console();

  late final FileSystemClient fs;
  late final Console console;
  final String projectRoot;
  final List<String> ignoredDirs;

  /// Execute [mapper] on all Dart files in project
  /// Aggregate the results and return
  Set<String> mapAllDartFilesInProject(Set<String> Function(String) mapper) {
    final result = <String>{};
    if (fs.directoryExists(p.join(projectRoot, 'lib'))) {
      try {
        for (var entity in fs.listFilesSync(projectRoot)) {
          if (fs.isFile(entity) &&
              entity.endsWith('.dart') &&
              !shouldIgnore(entity)) {
            result.addAll(mapper(entity));
          }
        }
      } catch (e) {
        throw 'Error traversing directory $projectRoot: $e';
      }
      return result;
    } else {
      throw 'Lib directory not found at $projectRoot';
    }
  }

  /// Find all files in a directory
  Set<String> findAllFilesInDirectory(String dir) {
    final files = <String>{};
    if (!fs.directoryExists(dir)) {
      console.printWarning('Assets directory not found at $dir');
      return files;
    }
    try {
      for (var entity in fs.listFilesSync(dir)) {
        if (fs.isFile(entity)) {
          if (!p.basename(entity).startsWith('.')) {
            files.add(
                p.relative(entity, from: projectRoot).replaceAll('\\', '/'));
          }
        }
      }
    } catch (e) {
      console.printError('Error listing files in $dir: $e');
    }
    if (files.isEmpty) {
      console.printWarning(
          'No files found in the assets directory $dir (Excluding hidden files)');
    } else {
      console
          .printInfo('\nFound ${files.length} files in the assets directory.');
    }
    return files;
  }

  /// Find all files from a set of directories
  Set<String> findAllFilesInDirectories(List<String> directories) {
    final result = <String>{};
    for (var dir in directories) {
      result.addAll(findAllFilesInDirectory(dir));
    }
    return result;
  }

  bool shouldIgnore(String path) {
    final filePath = path.replaceAll('\\', '/');
    final rootPath = projectRoot.replaceAll('\\', '/');
    return ignoredDirs.any((dir) {
      final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
      return filePath.contains(ignoredPath);
    });
  }
}
