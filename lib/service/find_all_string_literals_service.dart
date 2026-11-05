class FindAllStringLiteralsService {
  const FindAllStringLiteralsService({required this.content});
  final String content;

  /// Return all string literals from a blob of text
  Set<String> run() {
    final allNormalizedLiterals = <String>{};
    final stringLiteralRegex = RegExp(
        '\'(?:[^\\\'\\\\]|\\\\.)*\\\'|\\"(?:[^\\"\\\\]|\\\\.)*\\"|r\'[^\\\']*\\\'|r"[^\\"]*\\""',
        multiLine: true);

    final matches = stringLiteralRegex.allMatches(content);
    for (var match in matches) {
      String literal = match.group(0)!;
      String? normalized = _normalizeStringLiteral(literal);
      if (normalized != null && normalized.isNotEmpty) {
        allNormalizedLiterals.add(normalized);
      }
    }

    return allNormalizedLiterals;
  }

  /// Removes wrapping `r`, `'`, and `"` and extracts the string content itself
  ///
  /// Examples
  ///
  /// Input: `'Hello'`
  /// Output: `Hello`
  ///
  /// Input: `r"World's"`
  /// Output: `World's`
  static String? _normalizeStringLiteral(String literal) {
    if (literal.isEmpty) return null;
    String? content;
    if (literal.startsWith('r')) {
      if (literal.length >= 3) {
        content = literal.substring(2, literal.length - 1);
      }
    } else if ((literal.startsWith("'") && literal.endsWith("'")) ||
        (literal.startsWith('"') && literal.endsWith('"'))) {
      if (literal.length >= 2) {
        content = literal.substring(1, literal.length - 1);
      }
    }
    return content?.trim();
  }
}

/// ============
/// Old Implementation
/// ============
// static Set<String> run(
//     Directory dir, String projectRoot, List<String> ignoredDirs) {
//   final allNormalizedLiterals = <String>{};
//   final stringLiteralRegex = RegExp(
//       '\'(?:[^\\\'\\\\]|\\\\.)*\\\'|\\"(?:[^\\"\\\\]|\\\\.)*\\"|r\'[^\\\']*\\\'|r"[^\\"]*\\""',
//       multiLine: true);

//   void checkFile(File file) {
//     try {
//       final content = file.readAsStringSync();
//       final matches = stringLiteralRegex.allMatches(content);
//       for (var match in matches) {
//         String literal = match.group(0)!;
//         String? normalized = _normalizeStringLiteral(literal);
//         if (normalized != null && normalized.isNotEmpty) {
//           allNormalizedLiterals.add(normalized);
//         }
//       }
//     } catch (e) {
//       Ui.printError('Error reading file ${file.path}: $e');
//     }
//   }

//   if (dir.existsSync()) {
//     try {
//       for (var entity in dir.listSync(recursive: true)) {
//         if (entity is File &&
//             entity.path.endsWith('.dart') &&
//             !_shouldIgnore(entity, projectRoot, ignoredDirs)) {
//           checkFile(entity);
//         }
//       }
//     } catch (e) {
//       Ui.printError('Error traversing directory ${dir.path}: $e');
//     }
//   } else {
//     Ui.printError('Lib directory not found at ${dir.path}');
//   }
//   return allNormalizedLiterals;
// }

// static String? _normalizeStringLiteral(String literal) {
//   if (literal.isEmpty) return null;
//   String? content;
//   if (literal.startsWith('r')) {
//     if (literal.length >= 3) {
//       content = literal.substring(2, literal.length - 1);
//     }
//   } else if ((literal.startsWith("'") && literal.endsWith("'")) ||
//       (literal.startsWith('"') && literal.endsWith('"'))) {
//     if (literal.length >= 2) {
//       content = literal.substring(1, literal.length - 1);
//     }
//   }
//   return content?.trim();
// }

// static bool _shouldIgnore(
//     File file, String projectRoot, List<String> ignoredDirs) {
//   final filePath = file.path.replaceAll('\\', '/');
//   final rootPath = projectRoot.replaceAll('\\', '/');
//   return ignoredDirs.any((dir) {
//     final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
//     return filePath.contains(ignoredPath);
//   });
// }
