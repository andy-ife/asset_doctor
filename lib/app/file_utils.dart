import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  const FileUtils({
    required this.client,
    required this.console,
    required this.projectRoot,
  });

  final FileSystemClient client;
  final Console console;
  final String projectRoot;

  /// Find all files in a directory
  Set<String> findAllFilesInDirectory(String dir) {
    final files = <String>{};
    if (!client.directoryExists(dir)) {
      console.printWarning('Assets directory not found at $dir');
      return files;
    }
    try {
      for (var entity in client.listFilesSync(dir)) {
        if (client.isFile(entity)) {
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

  double calculateTotalFileSize(List<String> files) {
    return files.fold(0, (sum, curFile) {
      return client.fileExists(curFile)
          ? sum + client.lengthSync(curFile)
          : sum;
    });
  }
}
