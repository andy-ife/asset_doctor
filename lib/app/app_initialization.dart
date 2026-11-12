import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/directories.dart';
import 'package:asset_doctor/service/extract_pubspec_assets_service.dart';
import 'package:asset_doctor/service/find_all_string_literals_service.dart';
import 'package:asset_doctor/service/find_used_assets_service.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:path/path.dart' as p;

typedef AppInitialData = ({
  List<String> pubspecAssets,
  Set<String> allNormalizedLiterals,
  Set<String> allAssets,
  Set<String> usedAssets
});

class AppInitialization {
  AppInitialization({
    required this.projectRoot,
    required this.ignoredDirs,
    required this.pubspecPath,
    FileSystemClient? fs,
    Console? console,
  })  : fs = fs ?? FileSystemClient(projectRoot: projectRoot),
        console = console ?? Console();

  late final FileSystemClient fs;
  late final Console console;
  final String projectRoot;
  final List<String> ignoredDirs;
  final String pubspecPath;

  Future<AppInitialData> init() async {
    return await console.printLoading<AppInitialData>(
        message: "Finding project assets",
        work: () {
          final pubspecAssets = getPubspecAssets();
          final allNormalizedLiterals = getAllNormalizedLiterals();
          final allAssets = getAllAssets();
          final usedAssets = getUsedAssets(allAssets, allNormalizedLiterals);

          return (
            pubspecAssets: pubspecAssets,
            allNormalizedLiterals: allNormalizedLiterals,
            allAssets: allAssets,
            usedAssets: usedAssets
          );
        });
  }

  List<String> getPubspecAssets() {
    final pubspecContent = fs.readAsString(pubspecPath);
    return ExtractPubspecAssetsService(
            pubspecContent: pubspecContent, projectRoot: projectRoot)
        .run();
  }

  Set<String> getAllNormalizedLiterals() {
    return _mapAllDartFilesInProject((curFile) {
      final literals =
          FindAllStringLiteralsService(content: fs.readAsString(curFile)).run();
      return literals;
    });
  }

  Set<String> getAllAssets() {
    final assetsDirs = commonAssetLocations.values.expand((e) => e).toList();
    return _findAllFilesInDirectories(assetsDirs);
  }

  Set<String> getUsedAssets(
      Set<String> allAssets, Set<String> allNormalizedLiterals) {
    return FindUsedAssetsService(
            assetFiles: allAssets, allNormalizedLiterals: allNormalizedLiterals)
        .run();
  }

  // ===============
  // Helpers
  // ==============

  /// Execute [mapper] on all Dart files in project
  /// Aggregate the results and return
  Set<String> _mapAllDartFilesInProject(Set<String> Function(String) mapper) {
    final result = <String>{};
    if (fs.directoryExists(p.join(projectRoot, 'lib'))) {
      try {
        for (var entity in fs.listFilesSync(projectRoot)) {
          if (fs.isFile(entity) &&
              entity.endsWith('.dart') &&
              !_shouldIgnore(entity)) {
            result.addAll(mapper(entity));
          }
        }
      } catch (e) {
        final msg = 'Error traversing directory $projectRoot: $e';
        console.printError(msg);
        throw msg;
      }
      return result;
    } else {
      final msg = 'Lib directory not found at $projectRoot';
      console.printError(msg);
      throw msg;
    }
  }

  /// Find all files in a directory
  Set<String> _findAllFilesInDirectory(String dir, {bool isFirst = false}) {
    final files = <String>{};
    if (!fs.directoryExists(dir)) {
      console.printWarning(
          '${isFirst ? '\n' : ''}Assets directory not found at $dir');
      return files;
    }
    for (var entity in fs.listFilesSync(dir)) {
      try {
        if (fs.isFile(entity)) {
          if (!p.basename(entity).startsWith('.')) {
            files.add(
                p.relative(entity, from: projectRoot).replaceAll('\\', '/'));
          }
        }
      } catch (e) {
        console.printError('Error listing files in $dir: $e');
      }
    }
    if (files.isEmpty) {
      console.printWarning(
          '\nNo files found in the assets directory $dir (Excluding hidden files)');
    } else {
      console.printInfo('\nFound ${files.length} files in $dir.');
    }
    return files;
  }

  /// Find all files from a set of directories
  Set<String> _findAllFilesInDirectories(List<String> directories) {
    final result = <String>{};
    for (var dir in directories) {
      result.addAll(
          _findAllFilesInDirectory(dir, isFirst: directories.first == dir));
    }
    return result;
  }

  bool _shouldIgnore(String path) {
    final filePath = path.replaceAll('\\', '/');
    final rootPath = projectRoot.replaceAll('\\', '/');
    return ignoredDirs.any((dir) {
      final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
      return filePath.contains(ignoredPath);
    });
  }
}
