import 'dart:io';
import 'package:path/path.dart' as p;

enum MediaType { image, video, audio, text, unkown }

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
];

const audioExtensions = [
  '.m4a',
  '.mp3',
];

const textExtensions = [
  '.yaml',
  '.json',
  '.xml',
  '.txt',
  '',
];

extension MediaTypeExtension on File {
  bool get isImage => imageExtensions.contains(p.extension(absolute.path, 2));
  bool get isVideo => videoExtensions.contains(p.extension(absolute.path, 2));
  bool get isAudio => audioExtensions.contains(p.extension(absolute.path, 2));
  bool get isText => textExtensions.contains(p.extension(absolute.path, 2));

  MediaType get mediaType => isImage
      ? MediaType.image
      : isVideo
          ? MediaType.video
          : isAudio
              ? MediaType.audio
              : isText
                  ? MediaType.text
                  : MediaType.unkown;
}
