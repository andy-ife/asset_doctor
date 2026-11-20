enum AssetDir { assets, android, ios, macos, windows, linux }

// ignore: constant_identifier_names
const Map<AssetDir, List<String>> COMMON_ASSETS_LOCATIONS = {
  AssetDir.assets: ['assets', 'fonts', 'font'],
  AssetDir.android: ['android/app/src/main/res'],
  AssetDir.ios: ['ios/Runner/Assets.xcassets', 'ios/Runner/Fonts'],
  AssetDir.macos: ['macos/Runner/Assets.xcassets', 'macos/Runner/Fonts'],
  AssetDir.windows: ['windows/runner/resources', 'windows/runner/fonts'],
  AssetDir.linux: ['linux/runner/resources', 'linux/runner/fonts']
};
