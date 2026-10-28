import 'dart:io';
import 'package:path/path.dart' as p;

enum AssetType { image, video, audio, text, unkown }

const imageExtensions = [
  '.png',
  '.jpg',
  '.jpeg',
  '.jfif',
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
];

const audioExtensions = [
  '.m4a',
  '.mp3',
  '.ogg',
  '.opus',
];

const textExtensions = [
  '.yaml',
  '.json',
  '.xml',
  '.txt',
  '',
];

extension AssetTypeExtension on File {
  bool get isImage => imageExtensions.contains(p.extension(absolute.path, 2));
  bool get isVideo => videoExtensions.contains(p.extension(absolute.path, 2));
  bool get isAudio => audioExtensions.contains(p.extension(absolute.path, 2));
  bool get isText => textExtensions.contains(p.extension(absolute.path, 2));

  AssetType get assetType => isImage
      ? AssetType.image
      : isVideo
          ? AssetType.video
          : isAudio
              ? AssetType.audio
              : isText
                  ? AssetType.text
                  : AssetType.unkown;
}
