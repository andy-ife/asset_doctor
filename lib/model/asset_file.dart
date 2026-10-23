import 'package:asset_doctor/utils/asset.dart';

class AssetFile {
  const AssetFile(
      {required this.path,
      required this.type,
      required this.oldSize,
      required this.newSize});

  factory AssetFile.empty() {
    return AssetFile(path: '', type: AssetType.unkown, oldSize: 0, newSize: 0);
  }

  final String path;
  final AssetType type;
  final double oldSize;
  final double newSize;
}
