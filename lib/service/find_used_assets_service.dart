import 'package:path/path.dart' as p;

class FindUsedAssetsService {
  const FindUsedAssetsService(
      {required this.assetFiles, required this.allNormalizedLiterals});

  final Set<String> assetFiles;
  final Set<String> allNormalizedLiterals;

  /// Compare all asset files with all string literals from the source code.
  ///
  /// For an example file `foo.png`, we have the following strings:
  ///
  /// - filename: `foo.png`
  ///
  /// - path: `project/lib/assets/foo.png`
  ///
  /// - basename without extension: `foo`
  ///
  /// If any of these strings is found in the string literals set,
  /// we make an educated guess that the asset is used.
  ///
  /// Returns the list of used assets
  Set<String> run() {
    Set<String> usedAssetPaths = {};
    for (final assetPath in assetFiles) {
      final filename = p.basename(assetPath);
      final basenameWithoutExtension = p.basenameWithoutExtension(assetPath);

      final potentialReferences = [
        assetPath,
        filename,
        basenameWithoutExtension,
      ];

      final isUsed = allNormalizedLiterals.any((literal) {
        return potentialReferences.any((ref) => literal.contains(ref));
      });

      if (isUsed) {
        try {
          usedAssetPaths.add(assetPath);
        } catch (e) {
          // Do nothing. We should almost never throw errors here
          // And if we do, user already likely uses the asset in his app
        }
      }
    }
    return usedAssetPaths;
  }
}
