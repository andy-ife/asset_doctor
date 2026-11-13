import 'package:collection/collection.dart';

class CompressResult {
  const CompressResult(
      {required this.usedAssets,
      required this.assetsForCompression,
      required this.assetsForCompressionTree,
      required this.spaceOfMediaAssetsBeforeCompress,
      required this.spaceOfMediaAssetsAfterCompress,
      required this.hasAnalyzed,
      required this.hasCompressed});

  final Set<String> usedAssets;
  final List<String> assetsForCompression;
  final Map<String, dynamic> assetsForCompressionTree;
  final double spaceOfMediaAssetsBeforeCompress;
  final double? spaceOfMediaAssetsAfterCompress;
  final bool hasAnalyzed;
  final bool hasCompressed;

  CompressResult copyWith(
      {Set<String>? usedAssets,
      List<String>? assetsForCompression,
      Map<String, dynamic>? assetsForCompressionTree,
      double? spaceOfMediaAssetsBeforeCompress,
      double? Function()? spaceOfMediaAssetsAfterCompress,
      bool? hasAnalyzed,
      bool? hasCompressed}) {
    return CompressResult(
        usedAssets: usedAssets ?? this.usedAssets,
        assetsForCompression: assetsForCompression ?? this.assetsForCompression,
        assetsForCompressionTree:
            assetsForCompressionTree ?? this.assetsForCompressionTree,
        spaceOfMediaAssetsBeforeCompress: spaceOfMediaAssetsBeforeCompress ??
            this.spaceOfMediaAssetsBeforeCompress,
        spaceOfMediaAssetsAfterCompress: spaceOfMediaAssetsAfterCompress == null
            ? this.spaceOfMediaAssetsAfterCompress
            : spaceOfMediaAssetsAfterCompress(),
        hasAnalyzed: hasAnalyzed ?? this.hasAnalyzed,
        hasCompressed: hasCompressed ?? this.hasCompressed);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompressResult &&
            const SetEquality<String>().equals(usedAssets, other.usedAssets) &&
            const ListEquality<String>()
                .equals(assetsForCompression, other.assetsForCompression) &&
            const DeepCollectionEquality().equals(
                assetsForCompressionTree, other.assetsForCompressionTree) &&
            spaceOfMediaAssetsBeforeCompress ==
                other.spaceOfMediaAssetsBeforeCompress &&
            spaceOfMediaAssetsAfterCompress ==
                other.spaceOfMediaAssetsAfterCompress &&
            hasAnalyzed == other.hasAnalyzed &&
            hasCompressed == other.hasCompressed;
  }

  @override
  int get hashCode => Object.hash(
      const SetEquality<String>().hash(usedAssets),
      const ListEquality<String>().hash(assetsForCompression),
      const DeepCollectionEquality().hash(assetsForCompressionTree),
      spaceOfMediaAssetsBeforeCompress,
      spaceOfMediaAssetsAfterCompress,
      hasAnalyzed,
      hasCompressed);
}
