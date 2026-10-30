import 'dart:io';
import 'package:asset_doctor/utils/file_extension.dart';
import 'package:compressor/compressor.dart' as cp;
import 'package:image_compression/image_compression.dart';

class Compressor {
  const Compressor();

  Future<double> compressImage(File file) async {
    try {
      final input =
          ImageFile(filePath: file.path, rawBytes: file.readAsBytesSync());
      final output =
          await compressInQueue(ImageFileConfiguration(input: input));
      return output.sizeInBytes.toDouble();
    } catch (e) {
      rethrow;
    }
  }

  Future<double> compressVideo(File file) async {
    try {
      final compressor = cp.Compressor(path: file.path, isLocal: true);
      compressor.compressVideo();
      return File(file.path).lengthSync().toDouble();
    } catch (e) {
      rethrow;
    }
  }

  Future<double?> compressAudio(File file) async {
    print("Audio compression unsupported. Skipping ${file.path}");
    return null;
  }

  Future<double?> compressMedia(File file) async {
    switch (file.assetType) {
      case AssetType.image:
        return compressImage(file);
      case AssetType.video:
        return compressVideo(file);
      case AssetType.audio:
        return compressAudio(file);
      case AssetType.text:
        return null;
      case AssetType.unkown:
        return null;
    }
  }
}
