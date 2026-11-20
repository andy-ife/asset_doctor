import 'package:app_size_doctor/fix/app/models/compress_result.dart';
import 'package:app_size_doctor/fix/data/compression_client.dart';
import 'package:app_size_doctor/fix/data/file_system_client.dart';
import 'package:app_size_doctor/fix/ui/console.dart';
import 'package:app_size_doctor/fix/ui/extension.dart';
import 'package:app_size_doctor/fix/ui/tree.dart';
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
    this.projectRoot = projectRoot ?? fs.currentDir;
    this.client = client ?? CompressionClient(projectRoot: this.projectRoot);
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
        potentiallySavedSpace: spaceofMediaAssetsBeforeCompress * 0.6,
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

    var curResult = _result!;

    if (curResult.assetsForCompression.isNotEmpty) {
      String? shouldKeepSome;
      int? totalAssets;
      console.printInfo(
          '\n${curResult.assetsForCompression.length} assets are marked for compression. ');
      console.printInputPrompt(
          'Select some assets to ignore (remove from compression list)? (Y/N): ');
      do {
        shouldKeepSome = console.read();
        if (shouldKeepSome.isYes) {
          final toCompress = curResult.assetsForCompression;

          final indexes = console.printMultiSelect(
              message: '(Press <space> to select, <enter> to confirm)',
              options: toCompress);

          final toKeep = toCompress.indexed
              .where((e) => indexes.contains(e.$1))
              .map((e) => e.$2);

          totalAssets = toCompress.length;
          curResult = curResult.copyWith(
              assetsForCompression:
                  toCompress.where((e) => !toKeep.contains(e)).toList());
        } else if (shouldKeepSome.isNo) {
          // do nothing. Continue code
        } else {
          console.printError('Invalid option. Please enter "y" or "n"');
        }
      } while (!shouldKeepSome.isYesOrNo);

      if (curResult.assetsForCompression.isNotEmpty) {
        console.printWarning(
            '\nMarking ${shouldKeepSome.isYes ? '${curResult.assetsForCompression.length}/$totalAssets' : 'all'} media assets for compression...');
      } else {
        console.printSuccess('\n✨ Nothing to compress. Keeping all assets');
        return curResult;
      }
    } else {
      console.printSuccess("\n✨ Nothing to compress. No media assets found");
      return curResult;
    }

    String? finalConfirm;
    double freedSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to compress ${curResult.assetsForCompression.length} asset(s).');
    do {
      console.printInputPrompt(
          'Proceed with compression? It may take a while (Y/N): ');
      finalConfirm = console.read();
      if (finalConfirm.isYes) {
        freedSpace += await console.printLoading<double>(
            message:
                'Compressing ${curResult.assetsForCompression.length} asset(s)',
            work: () {
              final justFreed = compressAssets(curResult.assetsForCompression);
              if (justFreed > 0) {
                console.printSuccess(
                    '\n✨ You have freed up ${justFreed.toStorageString()} of space.');
              } else {
                console.printError('Unable to compress some assets');
              }
              return justFreed.clamp(0, double.infinity); // no negative nums
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
      final path = p.join(projectRoot, assetRelativePath);
      if (!fs.fileExists(path)) {
        console.printWarning(
            'File not found, skipping compression: "$assetRelativePath"');
        continue;
      }
      try {
        final res = client.compressMedia(path);
        result += (res ?? 0);
        if (res != null && res > 0) {
          console.printSuccess(
              '\nCompressed: $assetRelativePath: -${res.toStorageString()}');
        } else {
          console.printWarning(
              '\nCould not compress further: $assetRelativePath. Consider increasing the compression level');
        }
      } catch (e) {
        console.printError('Error compressing $path: $e');
      }
    }
    return result;
  }
}
