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

bool isImage(String path) => imageExtensions.contains(p.extension(path, 2));
bool isVideo(String path) => videoExtensions.contains(p.extension(path, 2));
bool isAudio(String path) => audioExtensions.contains(p.extension(path, 2));
bool isText(String path) => textExtensions.contains(p.extension(path, 2));

AssetType getAssetType(String path) => isImage(path)
    ? AssetType.image
    : isVideo(path)
        ? AssetType.video
        : isAudio(path)
            ? AssetType.audio
            : isText(path)
                ? AssetType.text
                : AssetType.unkown;
