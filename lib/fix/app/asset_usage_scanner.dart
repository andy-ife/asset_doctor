import 'package:app_size_doctor/fix/data/file_system_client.dart';
import 'package:app_size_doctor/fix/directories.dart';
import 'package:app_size_doctor/fix/service/extract_pubspec_assets_service.dart';
import 'package:app_size_doctor/fix/service/find_all_string_literals_in_file_service.dart';
import 'package:app_size_doctor/fix/service/match_assets_and_string_literals_service.dart';
import 'package:app_size_doctor/fix/ui/console.dart';
import 'package:path/path.dart' as p;

typedef AssetUsageScanResults = ({
  List<String> pubspecAssets,
  Set<String> allNormalizedLiterals,
  Set<String> allAssets,
  Set<String> usedAssets
});

class AssetUsageScanner {
  AssetUsageScanner({
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

  Future<AssetUsageScanResults> init() {
    return console.printLoading<AssetUsageScanResults>(
        message: "Finding assets and their usage",
        work: () {
          final pubspecAssets = getPubspecAssets();
          final allNormalizedLiterals = getAllNormalizedLiterals();
          final allAssets = getAllAssets();
          if (allAssets.isEmpty) {
            console.printWarning('No assets found in project');
            throw 'No assets found in project';
          }
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
          FindAllStringLiteralsInFileService(content: fs.readAsString(curFile))
              .run();
      return literals;
    });
  }

  Set<String> getAllAssets() {
    final assetsDirs = COMMON_ASSETS_LOCATIONS[AssetDir.assets]!;
    return _findAllFilesInDirectories(assetsDirs);
  }

  Set<String> getUsedAssets(
      Set<String> allAssets, Set<String> allNormalizedLiterals) {
    return MatchAssetsAndStringLiteralsService(
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
    final libDir = p.join(projectRoot, 'lib');
    if (fs.directoryExists(libDir)) {
      try {
        for (var entity in fs.listFilesSync(libDir)) {
          if (fs.isFile(entity) &&
              entity.endsWith('.dart') &&
              !_shouldIgnore(entity)) {
            result.addAll(mapper(entity));
          }
        }
      } catch (e) {
        final msg = 'Error traversing directory $libDir: $e';
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
      // console.printWarning(
      //     '${isFirst ? '\n' : ''}Assets directory not found at $dir');
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
        console.printError('Error listing files in /$dir: $e');
      }
    }
    if (files.isEmpty) {
      console.printWarning(
          '\nNo files found in the assets directory /$dir (Excluding hidden files)');
    } else {
      console.printInfo(
        '\nFound ${files.length} files in /$dir',
      );
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
