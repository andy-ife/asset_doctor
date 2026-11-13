import 'package:asset_doctor/app/models/compress_result.dart';
import 'package:asset_doctor/data/compression_client.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/ui/extension.dart';
import 'package:asset_doctor/ui/tree.dart';
import 'package:path/path.dart' as p;

class AssetCompressor {
  AssetCompressor({
    required this.usedAssets,
    required this.fs,
    CompressionClient? client,
    String? projectRoot,
    List<String>? ignoredDirs,
    Console? console,
    TreePrinter? tree,
  }) {
    this.client = client ?? CompressionClient();
    this.projectRoot = projectRoot ?? fs.currentDir;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
    this.console = console ?? Console();
    this.tree = tree ?? TreePrinter();
  }

  final Set<String> usedAssets;
  final FileSystemClient fs;

  late final CompressionClient client;
  late final String projectRoot;
  late final List<String> ignoredDirs; // Folders to ignore during code search
  late final Console console;
  late final TreePrinter tree;

  CompressResult? _result;
  CompressResult? get result => _result;

  CompressResult analyze() {
    final List<String> assetsForCompression = [];
    double spaceofMediaAssetsBeforeCompress = 0;

    final mediaAssets = usedAssets.where((e) => client.isMedia(e));

    for (final assetPath in mediaAssets) {
      final path = p.join(projectRoot, assetPath);
      bool isNonEmpty = false;
      try {
        if (fs.fileExists(path)) {
          final size = fs.lengthSync(path);
          isNonEmpty = size > 0;
          spaceofMediaAssetsBeforeCompress += size;
        }
      } catch (e) {
        console.printWarning('Could not check size of "$assetPath": $e');
      }

      if (isNonEmpty) {
        assetsForCompression.add(assetPath);
      }
    }

    final compressTree = tree.build(assetsForCompression);

    _result = CompressResult(
        usedAssets: mediaAssets.toSet(),
        assetsForCompression: assetsForCompression,
        assetsForCompressionTree: compressTree,
        spaceOfMediaAssetsBeforeCompress: spaceofMediaAssetsBeforeCompress,
        spaceOfMediaAssetsAfterCompress: null,
        hasAnalyzed: true,
        hasCompressed: false);
    return _result!;
  }

  Future<CompressResult?> compress() async {
    if (_result == null || _result?.hasAnalyzed == false) {
      console.printError('Run analysis before compression');
      return null;
    }

    final curResult = _result!;

    if (curResult.assetsForCompression.isNotEmpty) {
      console.printInfo('Marking media assets for compression');
    }

    String? finalConfirm;
    double freedSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to compress ${curResult.assetsForCompression.length} asset(s).');
    do {
      console.write('Proceed with compression? It may take a while (Y/N): ');
      finalConfirm = console.read();
      if (finalConfirm.isYes) {
        await console.printLoading<void>(
            message:
                'Compressing ${curResult.assetsForCompression.length} assets',
            work: () {
              freedSpace += compressAssets(curResult.assetsForCompression);

              if (freedSpace > 0) {
                console.printSuccess(
                    '\n✨ You have freed up ${freedSpace.toStorageString()} of space.');
              } else {
                console.printError('Unable to compress some assets');
              }
            });
      } else if (finalConfirm.isNo) {
        console.printError('Compression cancelled by user.');
        _result = curResult.copyWith(
            hasCompressed: false, spaceOfMediaAssetsAfterCompress: () => null);
        return _result;
      } else {
        console.printError('Invalid option. Please enter "y" or "n"');
      }
    } while (!finalConfirm.isYesOrNo);

    _result = curResult.copyWith(
      spaceOfMediaAssetsAfterCompress: () =>
          curResult.spaceOfMediaAssetsBeforeCompress - freedSpace,
      hasCompressed: true,
    );

    return _result;
  }

  double compressAssets(List<String> assets) {
    double result = 0;
    for (var assetRelativePath in assets) {
      final isFirst = assets.first == assetRelativePath;
      final path = p.join(projectRoot, assetRelativePath);
      if (!fs.fileExists(path)) {
        console.printWarning(
            'File not found, skipping compression: "$assetRelativePath"');
        continue;
      }
      try {
        final res = client.compressMedia(path);
        result += res ?? 0;
        if (result > 0) {
          console.printSuccess(
              '${isFirst ? '\n' : ''}Compressed: $assetRelativePath');
        } else {
          console.printWarning(
              '${isFirst ? '\n' : ''}Unable to compress: $assetRelativePath');
        }
      } catch (e) {
        console.printError('Error compressing $path: $e');
      }
    }
    return result;
  }
}
