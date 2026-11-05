enum AssetLocation { assets, android, ios, macos, windows, linux }

const Map<AssetLocation, List<String>> commonAssetLocations = {
  AssetLocation.assets: ['assets', 'fonts', 'font'],
  AssetLocation.android: ['android/app/src/main/res'],
  AssetLocation.ios: ['ios/Runner/Assets.xcassets', 'ios/Runner/Fonts'],
  AssetLocation.macos: ['macos/Runner/Assets.xcassets', 'macos/Runner/Fonts'],
  AssetLocation.windows: ['windows/runner/resources', 'windows/runner/fonts'],
  AssetLocation.linux: ['linux/runner/resources', 'linux/runner/fonts']
};
