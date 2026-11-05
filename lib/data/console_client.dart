import 'dart:io';

class ConsoleClient {
  void print() {
    return print();
  }

  void write(String value) {
    return stdout.write(value);
  }

  String? read() {
    return stdin.readLineSync();
  }
}
