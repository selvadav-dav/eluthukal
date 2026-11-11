/**
 * Script to generate frontend/lib/services/cloudinary_media.dart
 * from backend/database/cloudinary_image_map.json
 */
const fs = require('fs');
const path = require('path');

const mapPath = path.join(__dirname, '../../database/cloudinary_image_map.json');
const outDartPath = path.join(__dirname, '../../../frontend/lib/services/cloudinary_media.dart');

const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));

let dartContent = `// Generated Cloudinary Media Helper for AGARAM Educational Platform
// Contains CDN URLs for all frontend assets, games, GIFs, and backend images.

class CloudinaryMedia {
  static const String cloudName = 'dy8bu8suk';
  static const String folder = 'agaram_media';

  static const Map<String, String> _assetToCloudinaryMap = {
`;

// Sort keys alphabetically for clean diffs
const sortedKeys = Object.keys(map).sort();
for (const key of sortedKeys) {
  dartContent += `    ${JSON.stringify(key)}: ${JSON.stringify(map[key])},\n`;
}

dartContent += `  };

  /// Resolves any asset path, filename, or URL to its Cloudinary CDN URL.
  /// If no Cloudinary match exists, returns the original path.
  static String? getUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    
    // 1. Direct match (e.g. 'assets/images/amma.jpg', 'assets/Gif/car game.gif', etc.)
    if (_assetToCloudinaryMap.containsKey(clean)) {
      return _assetToCloudinaryMap[clean];
    }
    
    // 2. Check filename without directory path
    final fileName = clean.split('/').last;
    if (_assetToCloudinaryMap.containsKey(fileName)) {
      return _assetToCloudinaryMap[fileName];
    }

    // 3. Check with 'assets/images/' prefix
    final withImagesPrefix = 'assets/images/' + fileName;
    if (_assetToCloudinaryMap.containsKey(withImagesPrefix)) {
      return _assetToCloudinaryMap[withImagesPrefix];
    }

    // 4. Check with 'assets/Gif/' prefix
    final withGifPrefix = 'assets/Gif/' + fileName;
    if (_assetToCloudinaryMap.containsKey(withGifPrefix)) {
      return _assetToCloudinaryMap[withGifPrefix];
    }

    // 5. Check with 'assets/images/games/' prefix
    final withGamesPrefix = 'assets/images/games/' + fileName;
    if (_assetToCloudinaryMap.containsKey(withGamesPrefix)) {
      return _assetToCloudinaryMap[withGamesPrefix];
    }

    return clean;
  }

  /// Checks if a Cloudinary URL exists for this asset
  static bool hasCloudinaryUrl(String? path) {
    if (path == null) return false;
    final url = getUrl(path);
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }
}
`;

fs.writeFileSync(outDartPath, dartContent, 'utf8');
console.log('✅ Generated frontend/lib/services/cloudinary_media.dart successfully!');
