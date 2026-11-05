import 'dart:io';
import 'package:asset_doctor/data/asset_type.dart';
import 'package:compressor/compressor.dart' as cp;
import 'package:image_compression/image_compression.dart';

class CompressionClient {
  const CompressionClient();

  Future<double> compressImage(String path) async {
    final input =
        ImageFile(filePath: path, rawBytes: File(path).readAsBytesSync());
    final output = await compressInQueue(ImageFileConfiguration(input: input));
    return output.sizeInBytes.toDouble();
  }

  Future<double> compressVideo(String path) async {
    final compressor = cp.Compressor(path: path, isLocal: true);
    compressor.compressVideo();
    return File(path).lengthSync().toDouble();
  }

  Future<double?> compressAudio(String path) async {
    print("Audio compression unsupported. Skipping $path");
    return null;
  }

  Future<double?> compressMedia(String path) async {
    switch (getAssetType(path)) {
      case AssetType.image:
        return compressImage(path);
      case AssetType.video:
        return compressVideo(path);
      case AssetType.audio:
        return compressAudio(path);
      case AssetType.text:
        return null;
      case AssetType.unkown:
        return null;
    }
  }
}
