extension DoubleStorageFormatter on double {
  /// Converts a double value representing bytes into a human-readable string
  /// with 'b', 'MB', or 'GB' appended as appropriate.
  String toStorageString() {
    // Handle negative values or exactly 0 bytes
    if (this <= 0) return '0 b';

    const int gb = 1024 * 1024 * 1024;
    const int mb = 1024 * 1024;

    if (this >= gb) {
      double value = this / gb;
      return '${value.toStringAsFixed(2)} GB';
    } else if (this >= mb) {
      double value = this / mb;
      return '${value.toStringAsFixed(2)} MB';
    } else {
      // Formats as an integer string if it's a whole number,
      // otherwise keeps it as a regular double string for the raw bytes.
      return '${this.toInt()} b';
    }
  }
}
