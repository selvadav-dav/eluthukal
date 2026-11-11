import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/screens/games/games_screen.dart';
import 'package:tamil/screens/writing/writing_practice_screen.dart';
import 'package:tamil/services/progress_service.dart';

void main() {
  testWidgets('GamesScreen renders play.gif in header, our 6 core games, and no progress bars', (WidgetTester tester) async {
    final progressService = ProgressService();

    await tester.pumpWidget(
      MaterialApp(
        home: GamesScreen(progressService: progressService),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header elements
    expect(find.textContaining('விளையாட்டு'), findsWidgets);
    // Emoji 👧 is removed, replaced with play.gif
    expect(find.text('👧'), findsNothing);
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsWidgets);

    expect(find.byIcon(Icons.sports_esports_rounded), findsWidgets);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);

    // 2. Category Filter Pills are removed
    expect(find.text('அனைத்தும்'), findsNothing);
    expect(find.text('புதியவை'), findsNothing);
    expect(find.text('உயிர்'), findsNothing);
    expect(find.text('மெய்'), findsNothing);

    // 3. Two Options Switch: 'விளையாட்டுகள்' and 'எழுதிப் பழகு'
    expect(find.text('விளையாட்டுகள்'), findsOneWidget);
    expect(find.text('எழுதிப் பழகு'), findsOneWidget);

    // 4. Featured Games (Row 1):
    // Agaram Run play button 'விளையாடலாம்' is removed for clean artwork presentation
    expect(find.text('விளையாடலாம்'), findsNothing);
    expect(find.text('அகரம் ஓட்டம்'), findsNothing);
    // Letter Candy title overlay is removed
    expect(find.textContaining('தமிழ் எழுத்து'), findsNothing);

    // 5. Our other core games: game title badges are removed for clean artwork presentation
    expect(find.textContaining('கார் பந்தயம்'), findsNothing);
    expect(find.textContaining('மீன்பிடி'), findsNothing);
    expect(find.textContaining('(உயிர்)'), findsNothing);
    expect(find.textContaining('(மெய்)'), findsNothing);

    // 6. Coming Soon section is REMOVED
    expect(find.text('விரைவில் வருபவை'), findsNothing);

    // 7. Verify all 6 game-specific card images and play.gif are rendered
    final images = tester.widgetList<Image>(find.byType(Image));
    final assetNames = images
        .map((img) => img.image)
        .whereType<AssetImage>()
        .map((asset) => asset.assetName)
        .toList();

    expect(assetNames.contains('assets/images/play.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/candy crush game.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/agaram run game.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/car game.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/fish game.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/uyir eluthu kudai game.gif'), isTrue);
    expect(assetNames.contains('assets/Gif/Mei eluthu kudai game.gif'), isTrue);
    expect(assetNames.contains('assets/images/games/fruit_cutter.jpg'), isTrue);

    // 8. Verify sub-labels, badges, and progress bars are NOT present
    expect(find.text('புதியது'), findsNothing);
    expect(find.text('+3'), findsNothing);
    expect(find.text('2D ஓட்டப் பந்தயம்'), findsNothing);
    expect(find.text('Match-3 மிட்டாய்'), findsNothing);
    expect(find.text('ஓடி விளையாடி தமிழ் எழுத்துகளை கற்கலாம்!'), findsNothing);
    expect(find.text('எழுத்துகளை இணைத்து மதிப்பெண் பெறலாம்!'), findsNothing);

    // 9. Verify tapping 'எழுதிப் பழகு' navigates to WritingPracticeScreen
    await tester.tap(find.text('எழுதிப் பழகு'));
    await tester.pumpAndSettle();
    expect(find.byType(WritingPracticeScreen), findsOneWidget);
  });
}
