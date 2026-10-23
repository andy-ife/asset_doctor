import 'dart:io';
import 'dart:isolate';

import 'package:asset_doctor/model/asset_file.dart';
import 'package:asset_doctor/utils/asset.dart';
import 'package:ffmpeg_native_lib/ffmpeg_native_lib.dart';
import 'package:image_compression/image_compression.dart';

class Compressor {
  const Compressor();

  Future<AssetFile> compressImage(File file) {
    return Isolate.run(() async {
      final input =
          ImageFile(filePath: file.path, rawBytes: file.readAsBytesSync());
      final output =
          await compressInQueue(ImageFileConfiguration(input: input));
      return AssetFile(
          path: output.filePath,
          oldSize: file.lengthSync().toDouble(),
          newSize: output.sizeInBytes.toDouble(),
          type: AssetType.image);
    });
  }

  Future<AssetFile> compressVideo(File file) async {
    return AssetFile.empty();
  }

  Future<AssetFile> compressAudio(File file) async {
    print(avutilVersion);
    return AssetFile.empty();
  }

  Future<AssetFile?> compressMedia(File file) async {
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
