import 'package:asset_doctor/data/file_system_client.dart';
import 'package:path/path.dart' as p;

import 'package:compressor/compressor.dart' as cp;
import 'package:image_compression/image_compression.dart';

const imageExtensions = [
  '.png',
  '.jpg',
  '.jpeg',
  '.jfif',
  '.svg',
  '.tiff',
  '.gif',
  '.webp',
  '.avif',
  '.bmp'
];

const videoExtensions = [
  '.mp4',
  '.mkv',
  '.avi',
  '.webm',
];

const audioExtensions = [
  '.m4a',
  '.mp3',
  '.ogg',
  '.opus',
  '.wav',
];

const textExtensions = [
  '.yaml',
  '.json',
  '.xml',
  '.txt',
  '',
];

enum AssetType { image, video, audio, text, unkown }

class CompressionClient {
  CompressionClient({required this.projectRoot, FileSystemClient? fs})
      : fs = fs ?? FileSystemClient(projectRoot: projectRoot);

  final String projectRoot;
  late final FileSystemClient fs;

  bool isImage(String path) => imageExtensions.contains(p.extension(path, 2));
  bool isVideo(String path) => videoExtensions.contains(p.extension(path, 2));
  bool isAudio(String path) => audioExtensions.contains(p.extension(path, 2));
  bool isText(String path) => textExtensions.contains(p.extension(path, 2));
  bool isMedia(String path) => isImage(path) || isVideo(path) || isAudio(path);

  AssetType getAssetType(String path) => isImage(path)
      ? AssetType.image
      : isVideo(path)
          ? AssetType.video
          : isAudio(path)
              ? AssetType.audio
              : isText(path)
                  ? AssetType.text
                  : AssetType.unkown;

  double compressImage(String path) {
    final input = ImageFile(filePath: path, rawBytes: fs.readAsBytes(path));

    final output = compress(ImageFileConfiguration(
        input: input, config: Configuration(jpgQuality: 50)));

    fs.writeAsBytes(path, output.rawBytes);
    return (input.sizeInBytes - output.sizeInBytes).toDouble();
  }

  double compressVideo(String path) {
    final initialSize = fs.lengthSync(path);
    final compressor = cp.Compressor(path: path, isLocal: true);
    compressor.compressVideo();
    return (initialSize - fs.lengthSync(path)).toDouble();
  }

  double? compressAudio(String path) {
    // print("Audio compression unsupported. Skipping $path");
    return null;
  }

  double? compressMedia(String path) {
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

  double? compressAllMedia(Iterable<String> paths) {
    double result = 0;
    for (var p in paths) {
      final size = compressMedia(p) ?? 0;
      result += size;
    }
    return result;
  }
}
