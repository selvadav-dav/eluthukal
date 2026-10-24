import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/avatar_model.dart';
import 'package:tamil/screens/profile/profile_screen.dart';
import 'package:tamil/screens/settings/settings_screen.dart';
import 'package:tamil/services/progress_service.dart';
import 'package:tamil/services/tamil_transliteration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tamil Transliteration Service Tests', () {
    test('Translates English names to Tamil accurately', () {
      expect(TamilTransliterationService.toTamil('selva'), 'செல்வா');
      expect(TamilTransliterationService.toTamil('kavin'), 'கவின்');
      expect(TamilTransliterationService.toTamil('priya'), 'பிரியா');
      expect(TamilTransliterationService.toTamil('mithran'), 'மித்ரன்');
      expect(TamilTransliterationService.toTamil('anbu'), 'அன்பு');
      expect(TamilTransliterationService.toTamil('kumar'), 'குமார்');
      expect(TamilTransliterationService.toTamil('dharun'), 'தருண்');
      expect(TamilTransliterationService.toTamil('ram'), 'ராம்');
      expect(TamilTransliterationService.toTamil('siva'), 'சிவா');
      expect(TamilTransliterationService.toTamil('nila'), 'நிலா');
    });

    test('Preserves Tamil input as is without alteration', () {
      expect(TamilTransliterationService.toTamil('செல்வா'), 'செல்வா');
      expect(TamilTransliterationService.toTamil('கவின்'), 'கவின்');
      expect(TamilTransliterationService.toTamil('மலர்'), 'மலர்');
    });

    test('Handles multi-word names', () {
      expect(
        TamilTransliterationService.toTamil('selva kumar'),
        'செல்வா குமார்',
      );
      expect(
        TamilTransliterationService.toTamil('anbu chelvan'),
        'அன்பு செல்வன்',
      );
    });
  });

  group('App Avatar Catalogue Tests', () {
    test('AppAvatar list contains 2 mascot character avatars', () {
      expect(AppAvatar.list.length, 2);
      expect(AppAvatar.list[0].label, 'குட்டித் தம்பி');
      expect(AppAvatar.list[0].assetPath, 'assets/images/welcome.png');
      expect(AppAvatar.list[1].label, 'குட்டித் தங்கை');
      expect(AppAvatar.list[1].assetPath, 'assets/images/mascot_girl.png');
    });

    test('AppAvatar getAssetPath and getIndex helpers', () {
      expect(AppAvatar.getAssetPath(0), 'assets/images/welcome.png');
      expect(AppAvatar.getAssetPath(1), 'assets/images/mascot_girl.png');
      expect(AppAvatar.getIndex('assets/images/mascot_girl.png'), 1);
    });
  });

  group('Settings Screen and Profile Screen Widget Tests', () {
    testWidgets(
      'SettingsScreen displays character avatars, transliterates name and saves',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final progressService = ProgressService();
        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(progressService: progressService)),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Verify header and character avatar list
        expect(find.text('என் சுயவிவரம்'), findsOneWidget);
        expect(find.text('அவதாரத்தைத் தேர்ந்தெடுங்கள்'), findsOneWidget);
        expect(find.text('குட்டித் தம்பி'), findsOneWidget);
        expect(find.text('குட்டித் தங்கை'), findsOneWidget);

        // Verify TTS debug section is removed from settings
        expect(find.text('தமிழ் குரல் சோதனை (TTS Test)'), findsNothing);
        expect(find.text('தமிழ் குரல் கண்டறியப்படவில்லை'), findsNothing);

        // Type an English name "selva"
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(textFieldFinder, 'selva');
        await tester.pump();

        // Check live Tamil transliteration preview
        expect(find.text('செல்வா'), findsWidgets);

        // Tap Save
        await tester.tap(find.text('சேமி'));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify saved name in progress service
        expect(progressService.childName, 'செல்வா');
      },
    );

    testWidgets(
      'ProfileScreen renders child Tamil name, avatar, and statistics',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final progressService = ProgressService();
        await progressService.updateProfile(
          name: 'selva',
          avatarIndex: 1,
          age: 6,
        );

        await tester.pumpWidget(
          MaterialApp(home: ProfileScreen(progressService: progressService)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Tamil name 'செல்வா' is displayed
        expect(find.text('செல்வா'), findsOneWidget);
        expect(find.text('வயது: 6'), findsOneWidget);
        expect(find.text('சுயவிவரத்தைத் திருத்து'), findsOneWidget);
        expect(find.text('கற்றல் முன்னேற்றம்'), findsOneWidget);
        expect(find.text('மொத்த நட்சத்திரங்கள்'), findsOneWidget);
      },
    );
  });
}
