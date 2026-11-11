1. What if there is discrepancy between assets declared in pubspec.yaml and actual found files/directories.
2. Make the main runner more class-like to reduce passing args to every function
3. Revamp the printTree, buildTree, displayResults methods.
4. Wrap libraries in classes for improved testability
5. Display results by Root assets, Android, iOS, macOS, Windows, and Linux sections
6. Add getters to assetCleaner and assetCompressor. These are what assetAnalyzer, assetDoctor and others should use to access the cleaner's/compressor's properties
7. Add error handling to app.dart
8. Add support for passing projectRoot and ignoredDirs in app.dart arguments
9. Improve organisation/location of some files/deps
10. Consider Move the complex work from app.dart to file_utils
11. Add analysis cli mode