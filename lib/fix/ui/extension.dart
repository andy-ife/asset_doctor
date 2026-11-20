extension DoubleStorageFormatter on double {
  /// Converts a double value representing bytes into a human-readable string
  /// with 'b', 'MB', or 'GB' appended as appropriate.
  String toStorageString() {
    // Handle negative values or exactly 0 bytes
    if (this <= 0) return '0 b';

    const int gb = 1000 * 1000 * 1000;
    const int mb = 1000 * 1000;
    const int kb = 1000;

    if (this >= gb) {
      double value = this / gb;
      return '${value.toStringAsFixed(1)} GB';
    } else if (this >= mb) {
      double value = this / mb;
      return '${value.toStringAsFixed(1)} MB';
    } else if (this >= kb) {
      double value = this / kb;
      return '${value.toStringAsFixed(1)} KB';
    } else {
      // Formats as an integer string if it's a whole number,
      // otherwise keeps it as a regular double string for the raw bytes.
      return '${this.toInt()} b';
    }
  }
}

extension DoubleRounder on double {
  double get to1dp => (this * 10).round() / 10;
}

extension YesNoChecker on String? {
  bool get isYesOrNo => isYes || isNo;

  bool get isYes =>
      this != null &&
      (this!.toLowerCase().trim() == 'yes' ||
          this!.toLowerCase().trim() == 'y');

  bool get isNo =>
      this != null &&
      (this!.toLowerCase().trim() == 'no' || this!.toLowerCase().trim() == 'n');
}
