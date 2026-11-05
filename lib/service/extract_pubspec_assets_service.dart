import 'package:path/path.dart' as p;

final nameRegex = RegExp(r'^\s*name:\s*([a-z0-9_]+)', multiLine: true);
final environmentRegex =
    RegExp(r'^\s*environment:\s*\n(?:[ \t]+.+\n?)*', multiLine: true);

class ExtractPubspecAssetsService {
  const ExtractPubspecAssetsService(
      {required this.pubspecContent, required this.projectRoot});

  final String pubspecContent;
  final String projectRoot;

  /// Takes full raw text from pubspec.yaml and returns the list of assets from the
  /// assets section if present. The returned list is composed of both file and
  /// directory paths, so it is up to the caller to verify each
  ///
  /// [pubspecContent] is the raw text read from the pubspec file
  List<String> run() {
    assert(
        nameRegex.hasMatch(pubspecContent) &&
            environmentRegex.hasMatch(pubspecContent),
        'Invalid Dart/Flutter pubspec.yaml file. Missing name: and environment: sections');

    final assetRegex = RegExp(r'assets:\s*((?:\s+-\s+.+\n)+)', multiLine: true);
    final match = assetRegex.firstMatch(pubspecContent);
    if (match == null) return [];
    final assetLines = match
        .group(1)!
        .split('\n')
        .where((line) => line.trim().startsWith('-'))
        .map(
          (line) => line
              .trim()
              .substring(1)
              .trim()
              .replaceAll("'", '')
              .replaceAll('"', ''),
        )
        .toList();
    final assets = <String>[];
    for (var declaration in assetLines) {
      final fullPath = p.join(projectRoot, declaration);
      // final file = File(fullPath);
      // final dir = Directory(fullPath);
      // if (file.existsSync()) {
      //   assets.add(
      //     p.relative(file.path, from: projectRoot).replaceAll('\\', '/'),
      //   );
      // } else if (dir.existsSync()) {
      //   final filesInDir = _getFilesRecursivelyRelative(dir, projectRoot);
      //   assets.addAll(filesInDir);
      // } else {
      //   // Could not access declared asset
      // }
      assets.add(fullPath);
    }
    return assets;
  }
}
