import 'dart:io';
import 'dart:isolate';

import 'package:asset_doctor/compression/compressor.dart';
import 'package:asset_doctor/model/asset_file.dart';
import 'package:asset_doctor/utils/file_helper.dart';
import 'package:path/path.dart' as p;

class AssetCompressor {
  AssetCompressor({
    Compressor? compressor,
    String? projectRoot,
    Directory? assetsDir,
    List<String>? ignoredDirs,
  }) {
    this.compressor = compressor ?? Compressor();
    this.projectRoot = projectRoot ?? Directory.current.path;
    this.assetsDir = assetsDir ?? Directory(p.join(this.projectRoot, 'assets'));
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
  }

  late final Compressor compressor;
  late final String projectRoot;
  late final Directory assetsDir;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  List<Isolate> curIsolates = [];

  Map<String, dynamic> buildTree(List<String> paths) {
    return {};
  }

  void printTree(Map<String, dynamic> node, String prefic, bool isLast) {}

  int countFilesInTree(Map<String, dynamic> node) {
    return 0;
  }

  Future compressAllAssets() async {
    final assets = FileHelper.findAllFilesInCommonAssetLocations(projectRoot);
    final initialSize =
        FileHelper.calculateTotalFileSize(assets.map((e) => File(e)).toList());
    final compressedAssets = <AssetFile?>[];
    for (var asset in assets) {
      final file = File(asset);
      if (!file.existsSync()) continue;
      print('Compressing ${file.path}...');
      curIsolates.add(await Isolate.spawn((_) async {
        try {
          compressedAssets.add(await compressor.compressMedia(file));
        } catch (e) {
          rethrow;
        }
      }, null));
    }
    print("Successfully compressed all assets\n");
    print("Initial size: $initialSize");
    print(
        "Final size: ${FileHelper.calculateTotalAssetsSize(compressedAssets)}");
  }
}
