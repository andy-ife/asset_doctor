import 'dart:collection';

import 'package:asset_doctor/ui/console.dart';
import 'package:path/path.dart' as p;

class TreePrinter {
  TreePrinter({Console? console}) : console = console ?? Console();
  final Console console;

  Map<String, dynamic> paths = {};

  Map<String, dynamic> build(List<String> paths) {
    Map<String, dynamic> root = SplayTreeMap<String, dynamic>();
    for (var path in paths) {
      final parts = p.split(path);
      Map<String, dynamic> currentNode = root;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1) {
          currentNode[part] = true;
        } else {
          currentNode.putIfAbsent(part, () => SplayTreeMap<String, dynamic>());
          currentNode = currentNode[part];
        }
      }
    }
    this.paths = root;
    return root;
  }

  void print({Map<String, dynamic>? paths, String? prefix}) {
    final node = paths ?? this.paths;
    final keys = node.keys.toList();
    final prefix0 = prefix ?? '';

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final isLastEntry = (i == keys.length - 1);
      final entityPrefix = isLastEntry ? '└── ' : '├── ';
      final childPrefix = prefix0 + (isLastEntry ? '    ' : '│   ');
      console.printDefault('$prefix0$entityPrefix$key');
      if (node[key] is Map) {
        print(
          paths: node[key],
          prefix: childPrefix,
        );
      }
    }
  }

  void printTree(List<String> paths) {
    build(paths);
    print();
  }
}
