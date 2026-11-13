import 'package:collection/collection.dart';

class CleanResult {
  const CleanResult(
      {required this.allAssets,
      required this.usedAssets,
      required this.unusedAssetsForDeletion,
      required this.unusedTree,
      required this.excludedTree,
      required this.spaceOfUnusedAssetsBeforeClean,
      required this.spaceOfUnusedAssetsAfterClean,
      required this.hasAnalyzed,
      required this.hasCleaned});

  final Set<String> allAssets;
  final Set<String> usedAssets;
  final List<String> unusedAssetsForDeletion;
  final Map<String, dynamic> unusedTree;
  final Map<String, dynamic> excludedTree;
  final double spaceOfUnusedAssetsBeforeClean;
  final double? spaceOfUnusedAssetsAfterClean;
  final bool hasAnalyzed;
  final bool hasCleaned;

  CleanResult copyWith(
      {Set<String>? allAssets,
      Set<String>? usedAssets,
      List<String>? unusedAssetsForDeletion,
      Map<String, dynamic>? unusedTree,
      Map<String, dynamic>? excludedTree,
      double? spaceOfUnusedAssetsBeforeClean,
      double? Function()? spaceOfUnusedAssetsAfterClean,
      bool? hasAnalyzed,
      bool? hasCleaned}) {
    return CleanResult(
        allAssets: allAssets ?? this.allAssets,
        usedAssets: usedAssets ?? this.usedAssets,
        unusedAssetsForDeletion:
            unusedAssetsForDeletion ?? this.unusedAssetsForDeletion,
        unusedTree: unusedTree ?? this.unusedTree,
        excludedTree: excludedTree ?? this.excludedTree,
        spaceOfUnusedAssetsBeforeClean: spaceOfUnusedAssetsBeforeClean ??
            this.spaceOfUnusedAssetsBeforeClean,
        spaceOfUnusedAssetsAfterClean: spaceOfUnusedAssetsAfterClean == null
            ? this.spaceOfUnusedAssetsAfterClean
            : spaceOfUnusedAssetsAfterClean(),
        hasAnalyzed: hasAnalyzed ?? this.hasAnalyzed,
        hasCleaned: hasCleaned ?? this.hasCleaned);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CleanResult &&
            const SetEquality<String>().equals(allAssets, other.allAssets) &&
            const SetEquality<String>().equals(usedAssets, other.usedAssets) &&
            const ListEquality<String>().equals(
                unusedAssetsForDeletion, other.unusedAssetsForDeletion) &&
            const DeepCollectionEquality()
                .equals(unusedTree, other.unusedTree) &&
            const DeepCollectionEquality()
                .equals(excludedTree, other.excludedTree) &&
            spaceOfUnusedAssetsBeforeClean ==
                other.spaceOfUnusedAssetsBeforeClean &&
            spaceOfUnusedAssetsAfterClean ==
                other.spaceOfUnusedAssetsAfterClean &&
            hasAnalyzed == other.hasAnalyzed &&
            hasCleaned == other.hasCleaned;
  }

  @override
  int get hashCode => Object.hash(
      const SetEquality<String>().hash(allAssets),
      const SetEquality<String>().hash(usedAssets),
      const ListEquality<String>().hash(unusedAssetsForDeletion),
      const DeepCollectionEquality().hash(unusedTree),
      const DeepCollectionEquality().hash(excludedTree),
      spaceOfUnusedAssetsBeforeClean,
      spaceOfUnusedAssetsAfterClean,
      hasAnalyzed,
      hasCleaned);
}
