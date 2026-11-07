class FindAllStringLiteralsService {
  const FindAllStringLiteralsService({required this.content});
  final String content;

  /// Return all string literals from a blob of text from a file
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

