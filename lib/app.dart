import 'dart:io';
import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_cleaner.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/asset_doctor.dart';
import 'package:asset_doctor/file_utils.dart';
import 'package:asset_doctor/directories.dart';
import 'package:asset_doctor/service/extract_pubspec_assets_service.dart';
import 'package:asset_doctor/service/find_all_string_literals_service.dart';
import 'package:asset_doctor/service/find_used_assets_service.dart';
import 'package:asset_doctor/ui/cli.dart';
import 'package:path/path.dart' as p;

class App {
  static void start(List<String> args) {
    final projectRoot = Directory.current.path;
    final ignoredDirs = ['test', 'build', 'integration_test'];
    final fut = FileUtils(projectRoot: projectRoot, ignoredDirs: ignoredDirs);

    final cliMode = Cli().start(args);

    // Pubspec
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    final pubspecContent = fut.fs.readAsString(pubspecPath);
    final pubspecAssets = ExtractPubspecAssetsService(
            pubspecContent: pubspecContent, projectRoot: projectRoot)
        .run();

    // String literals
    final Set<String> normalizedLiterals =
        fut.mapAllDartFilesInProject((curFile) {
      final literals =
          FindAllStringLiteralsService(content: fut.fs.readAsString(curFile))
              .run();
      return literals;
    });

    // All Assets
    final assetsDirs = commonAssetLocations.values.expand((e) => e).toList();
    final allAssets = fut.findAllFilesInDirectories(assetsDirs);

    // Used Assets
    final usedAssets = FindUsedAssetsService(
            assetFiles: allAssets, allNormalizedLiterals: normalizedLiterals)
        .run();

    // Start
    final assetDoctor = AssetDoctor(
        cliMode: cliMode,
        assetCleaner: AssetCleaner(
            allAssets: allAssets, usedAssets: usedAssets, fs: fut.fs),
        assetCompressor: AssetCompressor(usedAssets: usedAssets, fs: fut.fs),
        analysisPrinter: AnalysisPrinter(
            usedAssets: usedAssets, pubspecAssets: pubspecAssets, fs: fut.fs));

    assetDoctor.run();
  }
}
