import 'package:asset_doctor/compression/compressor.dart';

class AssetCompressor {
  AssetCompressor({Compressor? compressor})
      : compressor = compressor ?? Compressor();

  final Compressor compressor;
}
