/// Definition and catalogue of rich character/mascot avatars available across AGARAM app
class AppAvatar {
  final int index;
  final String label;
  final String assetPath;

  const AppAvatar({
    required this.index,
    required this.label,
    required this.assetPath,
  });

  static const List<AppAvatar> list = [
    AppAvatar(
      index: 0,
      label: 'குட்டித் தம்பி',
      assetPath: 'assets/images/welcome.png',
    ),
    AppAvatar(
      index: 1,
      label: 'குட்டித் தங்கை',
      assetPath: 'assets/images/mascot_girl.png',
    ),
  ];

  static String getAssetPath(int index) {
    if (index >= 0 && index < list.length) {
      return list[index].assetPath;
    }
    return list[0].assetPath;
  }

  static int getIndex(String assetPath) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].assetPath == assetPath) return i;
    }
    return 0;
  }
}
