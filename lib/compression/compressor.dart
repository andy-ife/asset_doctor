import 'dart:io';
import 'dart:isolate';

import 'package:asset_doctor/model/asset_file.dart';
import 'package:asset_doctor/utils/file_extension.dart';
import 'package:compressor/compressor.dart' as cp;
import 'package:image_compression/image_compression.dart';

class Compressor {
  const Compressor();

  Future<AssetFile> compressImage(File file) {
    return Isolate.run(() async {
      try {
        final input =
            ImageFile(filePath: file.path, rawBytes: file.readAsBytesSync());
        final output =
            await compressInQueue(ImageFileConfiguration(input: input));
        return AssetFile(
            path: output.filePath,
            oldSize: file.lengthSync().toDouble(),
            newSize: output.sizeInBytes.toDouble(),
            type: AssetType.image);
      } catch (e) {
        rethrow;
      }
    });
  }

  Future<AssetFile> compressVideo(File file) async {
    return Isolate.run(() async {
      try {
        final oldsize = file.lengthSync();
        final compressor = cp.Compressor(path: file.path, isLocal: true);
        String result = compressor.compressVideo();
        return AssetFile(
            path: file.path,
            oldSize: oldsize.toDouble(),
            newSize: File(file.path).lengthSync().toDouble(),
            type: AssetType.video);
      } catch (e) {
        rethrow;
      }
    });
  }

  Future<AssetFile?> compressAudio(File file) async {
    print("Audio compression unsupported. Skipping ${file.path}");
    return null;
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
