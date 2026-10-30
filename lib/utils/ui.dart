import 'dart:io';

const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String cyan = '\x1B[36m';

class Ui {
  static void printError(String message) {
    print('$red$message$reset');
  }

  static void printInfo(String message) {
    print('$cyan$message$reset');
  }

  static void printWarning(String message) {
    print('$yellow$message$reset');
  }

  static void printSuccess(String message) {
    print('$green$message$reset');
  }

  static void printDefault(String message) {
    print(message);
  }

  static void printLoading(
      {required String message, required Stream work}) async {
    int i = 0;
    bool loading = true;
    work.listen((data) {}, onError: (e) {
      loading = false;
    }, onDone: () {
      loading = false;
      // Clear the line and print completion message
      // stdout.write('\rDone!              \n');
    });

    while (loading) {
      String dots = '.' * ((i % 3) + 1);
      stdout.write('\r$message$dots');
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  static void printTree(Map<String, dynamic> node, String prefix, bool isLast) {
    final keys = node.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final isLastEntry = (i == keys.length - 1);
      final entityPrefix = isLastEntry ? '└── ' : '├── ';
      final childPrefix = prefix + (isLastEntry ? '    ' : '│   ');
      Ui.printDefault('$prefix$entityPrefix$key');
      if (node[key] is Map) {
        printTree(node[key], childPrefix, isLastEntry);
      }
    }
  }
}
