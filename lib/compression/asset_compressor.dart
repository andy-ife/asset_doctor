import 'dart:io';
import 'dart:isolate';

import 'package:asset_doctor/compression/compressor.dart';

class AssetCompressor {
  AssetCompressor({
    Compressor? compressor,
    String? projectRoot,
    List<String>? ignoredDirs,
  }) {
    this.compressor = compressor ?? Compressor();
    this.projectRoot = projectRoot ?? Directory.current.path;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
  }

  late final Compressor compressor;
  late final String projectRoot;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  List<Isolate> curIsolates = [];

  void displayResults(Set<String> allAssetFiles,
      List<String> filesForCompression, Map<String, dynamic> tree) {}

  Future<double> compressAssets(List<String> assets) async {
    double result = 0;
    for (var asset in assets) {
      final file = File(asset);
      if (!file.existsSync()) continue;
      print('Compressing ${file.path}...');
      curIsolates.add(await Isolate.spawn((_) async {
        try {
          final res = await compressor.compressMedia(file);
          result += res ?? 0;
        } catch (e) {
          rethrow;
        }
      }, null));
    }
    return result;
  }
}
