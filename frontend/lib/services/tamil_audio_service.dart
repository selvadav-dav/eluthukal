import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'tamil_tts_service.dart';

/// Centralized Tamil Audio Service for the AGARAM Educational Platform.
/// Powered by pre-generated and cached ElevenLabs audio assets with seamless TamilTtsService fallback.
/// Resolves and plays any of the 247 Tamil letters, words, sentences, stories, and quizzes.
class TamilAudioService {
  static final TamilAudioService _instance = TamilAudioService._internal();
  factory TamilAudioService() => _instance;
  static TamilAudioService get instance => _instance;

  TamilAudioService._internal();

  AudioPlayer? _player;
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  AudioPlayer get player {
    if (_player == null) {
      _player = AudioPlayer();
      _configureAudioContext(_player!);
    }
    return _player!;
  }

  void _configureAudioContext(AudioPlayer p) {
    try {
      p.setVolume(1.0);
      p.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TamilAudioService] AudioContext configuration: $e');
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    TamilTtsService.instance.setMuted(muted);
    if (muted) {
      stopAll();
    }
  }

  // --------------------------------------------------------------------------
  // Static Audio Asset Mappings for 247 Letters and Core Content
  // --------------------------------------------------------------------------
  static final Map<String, String> _audioMapping = _buildAudioMapping();

  static Map<String, String> _buildAudioMapping() {
    final map = <String, String>{};

    // 12 Uyir Letters
    const uyirSlugs = <String, String>{
      'அ': 'assets/sounds/uyir/uyir_a.mp3',
      'ஆ': 'assets/sounds/uyir/uyir_aa.mp3',
      'இ': 'assets/sounds/uyir/uyir_i.mp3',
      'ஈ': 'assets/sounds/uyir/uyir_ee.mp3',
      'உ': 'assets/sounds/uyir/uyir_u.mp3',
      'ஊ': 'assets/sounds/uyir/uyir_oo.mp3',
      'எ': 'assets/sounds/uyir/uyir_e.mp3',
      'ஏ': 'assets/sounds/uyir/uyir_ae.mp3',
      'ஐ': 'assets/sounds/uyir/uyir_ai.mp3',
      'ஒ': 'assets/sounds/uyir/uyir_o.mp3',
      'ஓ': 'assets/sounds/uyir/uyir_oo_long.mp3',
      'ஔ': 'assets/sounds/uyir/uyir_au.mp3',
    };
    for (final entry in uyirSlugs.entries) {
      map[entry.key] = entry.value;
    }
    map['uyir_1'] = 'assets/sounds/uyir/uyir_a.mp3';
    map['uyir_a'] = 'assets/sounds/uyir/uyir_a.mp3';

    // 18 Mei Letters
    const meiSlugs = <String, String>{
      'க்': 'mei_01_ik',
      'ங்': 'mei_02_ing',
      'ச்': 'mei_03_ich',
      'ஞ்': 'mei_04_inj',
      'ட்': 'mei_05_it',
      'ண்': 'mei_06_inn',
      'த்': 'mei_07_ith',
      'ந்': 'mei_08_inth',
      'ப்': 'mei_09_ip',
      'ம்': 'mei_10_im',
      'ய்': 'mei_11_iy',
      'ர்': 'mei_12_ir',
      'ல்': 'mei_13_il',
      'வ்': 'mei_14_iv',
      'ழ்': 'mei_15_izh',
      'ள்': 'mei_16_ill',
      'ற்': 'mei_17_irr',
      'ன்': 'mei_18_in',
    };
    for (final entry in meiSlugs.entries) {
      map[entry.key] = 'assets/audio/tamil/mei/${entry.value}.mp3';
    }

    // 1 Aytham Letter
    map['ஃ'] = 'assets/audio/tamil/aytham/aytham_01_ak.mp3';
    map['ak'] = 'assets/audio/tamil/aytham/aytham_01_ak.mp3';
    map['Ak'] = 'assets/audio/tamil/aytham/aytham_01_ak.mp3';
    map['அக்கு'] = 'assets/audio/tamil/aytham/aytham_01_ak.mp3';

    // Operator and special symbols (+ / கூட்டல்)
    map['+'] = 'assets/audio/tamil/plus.mp3';
    map['கூட்டல்'] = 'assets/audio/tamil/plus.mp3';
    map['plus'] = 'assets/audio/tamil/plus.mp3';

    // 216 Uyirmei Combinations (18 Mei × 12 Uyir)
    const meiKeys = [
      'k', 'ng', 'c', 'nj', 't', 'nn', 'th', 'nth', 'p', 'm', 'y', 'r', 'l', 'v', 'zh', 'll', 'rr', 'n'
    ];
    const vowelKeys = [
      'a', 'aa', 'i', 'ee', 'u', 'oo', 'e', 'ae', 'ai', 'o', 'oo_long', 'au'
    ];

    const uyirmeiMatrix = <String, List<String>>{
      'க்': ['க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ'],
      'ங்': ['ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ'],
      'ச்': ['ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ'],
      'ஞ்': ['ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ'],
      'ட்': ['ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ'],
      'ண்': ['ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ'],
      'த்': ['த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ'],
      'ந்': ['ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ'],
      'ப்': ['ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ'],
      'ம்': ['ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ'],
      'ய்': ['ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ'],
      'ர்': ['ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ'],
      'ல்': ['ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ'],
      'வ்': ['வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ'],
      'ழ்': ['ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ'],
      'ள்': ['ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ'],
      'ற்': ['ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ'],
      'ன்': ['ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ'],
    };

    int count = 0;
    final meiEntries = uyirmeiMatrix.entries.toList();
    for (int m = 0; m < meiEntries.length; m++) {
      final combinations = meiEntries[m].value;
      final baseKey = (m < meiKeys.length) ? meiKeys[m] : 'm$m';
      final meiChar = meiEntries[m].key;

      for (int v = 0; v < combinations.length; v++) {
        count++;
        final letter = combinations[v];
        final indexStr = count.toString().padLeft(3, '0');
        final suffix = (v < vowelKeys.length) ? vowelKeys[v] : 'v$v';
        final slug = 'uyirmei_${indexStr}_${baseKey}_$suffix';
        map[letter] = 'assets/audio/tamil/uyirmei/$slug.mp3';

        // Map composite/spaced combinations (e.g. 'ள் ஒள' and 'ள் ஔ' -> 'ளௌ' audio)
        if (v == 11) {
          map['$meiChar ஔ'] = 'assets/audio/tamil/uyirmei/$slug.mp3';
          map['$meiChar ஒள'] = 'assets/audio/tamil/uyirmei/$slug.mp3';
          map['$meiCharஔ'] = 'assets/audio/tamil/uyirmei/$slug.mp3';
          map['$meiCharஒள'] = 'assets/audio/tamil/uyirmei/$slug.mp3';
        }
      }
    }

    // Essential Vocabulary Words (Including all 18 Mei sample words)
    const wordSlugs = <String, String>{
      'அம்மா': 'word_amma',
      'ஆடு': 'word_aadu',
      'இலை': 'word_ilai',
      'ஈ': 'word_ee',
      'உரல்': 'word_ural',
      'ஊஞ்சல்': 'word_oonjal',
      'எலி': 'word_eli',
      'ஏணி': 'word_eani',
      'ஐந்து': 'word_ainthu',
      'ஒட்டகம்': 'word_ottagam',
      'ஓடம்': 'word_oodam',
      'ஔவையார்': 'word_auvaiyar',
      'தமிழ்': 'word_thamizh',
      'எஃகு': 'word_ehgu',
      'மரம்': 'word_maram',
      'பட்டம்': 'word_pattam',
      'கண்': 'word_kann',
      'பந்து': 'word_panthu',
      // 18 Mei Sample Words (Including Admin Panel customized items)
      'சக்கரம்': 'word_sakkaram',
      'சங்கு': 'word_sangu',
      'எலுமிச்சை': 'word_elumichai',
      'தச்சர்': 'word_thacchar',
      'நத்தை': 'word_nathai',
      'கப்பல்': 'word_kappal',
      'பாய்': 'word_paai',
      'தேர்': 'word_thear',
      'ஏர்': 'word_ear',
      'சேவல்': 'word_seval',
      'செவ்வானம்': 'word_sevvaanam',
      'செவ்வந்தி': 'word_sevvanthi',
      'யாழ்': 'word_yaazh',
      'வாள்': 'word_vaal',
      'வெற்றிலை': 'word_vetrilai',
      'புற்று': 'word_putru',
      'மீன்': 'word_meen',
      'வணக்கம்': 'word_vanakkam',
      'வணக்கம். இது அகரம் தமிழ் குரல் சோதனை.': 'sentence_greeting_test',
      'அ ஆ இ ஈ உ ஊ': 'sentence_alphabet_test',
    };
    for (final entry in wordSlugs.entries) {
      final category = entry.value.startsWith('sentence_') ? 'sentences' : 'words';
      map[entry.key] = 'assets/audio/tamil/$category/${entry.value}.mp3';
    }

    // Additional pre-generated vocabulary words mapped to their hex asset files
    const hexWordSlugs = <String, String>{
      'காடு': 'word_e0ae95e0aebee0ae9fe0af81',
      'முயல்': 'word_e0aeaee0af81e0aeafe0aeb2e0af8d',
      'ஆமை': 'word_e0ae86e0aeaee0af88',
      'காக்கை': 'word_e0ae95e0aebee0ae95e0af8de0ae95e0af88',
      'கிளி': 'word_e0ae95e0aebfe0aeb3e0aebf',
      'கீரை': 'word_e0ae95e0af80e0aeb0e0af88',
      'குடை': 'word_e0ae95e0af81e0ae9fe0af88',
      'கூடு': 'word_e0ae95e0af82e0ae9fe0af81',
      'கெண்டை': 'word_e0ae95e0af86e0aea3e0af8de0ae9fe0af88',
      'கேடயம்': 'word_e0ae95e0af87e0ae9fe0aeafe0aeaee0af8d',
      'கை': 'word_e0ae95e0af88',
      'கொக்கு': 'word_e0ae95e0af8ae0ae95e0af8de0ae95e0af81',
      'கோழி': 'word_e0ae95e0af8be0aeb4e0aebf',
      'கௌதாரி': 'word_e0ae95e0af8ce0aea4e0aebee0aeb0e0aebf',
      'சட்டை': 'word_e0ae9ae0ae9fe0af8de0ae9fe0af88',
      'சாவி': 'word_e0ae9ae0aebee0aeb5e0aebf',
      'சிங்கம்': 'word_e0ae9ae0aebfe0ae99e0af8de0ae95e0aeaee0af8d',
      'சீப்பு': 'word_e0ae9ae0af80e0aeaae0af8de0aeaae0af81',
      'தவளை': 'word_e0aea4e0aeb5e0aeb3e0af88',
      'தாமரை': 'word_e0aea4e0aebee0aeaee0aeb0e0af88',
      'திமிங்கலம்': 'word_e0aea4e0aebfe0aeaee0aebfe0ae99e0af8de0ae95e0aeb2e0aeaee0af8d',
      'தீபம்': 'word_e0aea4e0af80e0aeaae0aeaee0af8d',
      'பால்': 'word_e0aeaae0aebee0aeb2e0af8d',
      'பிள்ளை': 'word_e0aeaae0aebfe0aeb3e0af8de0aeb3e0af88',
      'பீர்க்கு': 'word_e0aeaae0af80e0aeb0e0af8de0ae95e0af8de0ae95e0af81',
      'மயில்': 'word_e0aeaee0aeafe0aebfe0aeb2e0af8d',
      'மாம்பழம்': 'word_e0aeaee0aebee0aeaee0af8de0aeaae0aeb4e0aeaee0af8d',
      'மிளகாய்': 'word_e0aeaee0aebfe0aeb3e0ae95e0aebee0aeafe0af8d',
      'மீன்': 'word_e0aeaee0af80e0aea9e0af8d',
    };
    for (final entry in hexWordSlugs.entries) {
      map[entry.key] = 'assets/audio/tamil/words/${entry.value}.mp3';
    }

    // Story Narrations and Sentences
    const storyMappings = <String, String>{
      'முயலும் ஆமையும்': 'assets/audio/tamil/stories/story_title.mp3',
      'ஒரு காட்டில் முயலும் ஆமையும் வாழ்ந்தன.': 'assets/audio/tamil/stories/story_page_1.mp3',
      'முயல் வேகமாக ஓடும்.\nஆமை மெதுவாக நடக்கும்.': 'assets/audio/tamil/stories/story_page_2.mp3',
      'முயல் வேகமாக ஓடும். ஆமை மெதுவாக நடக்கும்.': 'assets/audio/tamil/stories/story_page_2.mp3',
      'இருவரும் ஓட்டப்பந்தயம் வைத்தனர்.\nமுயல் வேகமாக ஓடியது.': 'assets/audio/tamil/stories/story_page_3.mp3',
      'இருவரும் ஓட்டப்பந்தயம் வைத்தனர். முயல் வேகமாக ஓடியது.': 'assets/audio/tamil/stories/story_page_3.mp3',
      'முயல் மரத்தடியில் தூங்கிவிட்டது.\nஆமை தொடர்ந்து நடந்தது.': 'assets/audio/tamil/stories/story_page_4.mp3',
      'முயல் மரத்தடியில் தூங்கிவிட்டது. ஆமை தொடர்ந்து நடந்தது.': 'assets/audio/tamil/stories/story_page_4.mp3',
      'ஆமை முதலில் சென்றது.\nபோட்டியில் வெற்றி பெற்றது!': 'assets/audio/tamil/stories/story_page_5.mp3',
      'ஆமை முதலில் சென்றது. போட்டியில் வெற்றி பெற்றது!': 'assets/audio/tamil/stories/story_page_5.mp3',
      'முயல் தன் தவறை உணர்ந்தது.\nவிடாமுயற்சி வெற்றி தரும்!': 'assets/audio/tamil/stories/story_page_6.mp3',
      'முயல் தன் தவறை உணர்ந்தது. விடாமுயற்சி வெற்றி தரும்!': 'assets/audio/tamil/stories/story_page_6.mp3',
      'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்!': 'assets/audio/tamil/stories/story_moral.mp3',
    };
    for (final entry in storyMappings.entries) {
      map[entry.key] = entry.value;
    }

    // Quiz Questions, Options, and Category Titles
    const quizMappings = <String, String>{
      // Category Titles
      'உயிர் எழுத்துகள்': 'assets/audio/tamil/quizzes/cat_uyir.mp3',
      'மெய் எழுத்துகள்': 'assets/audio/tamil/quizzes/cat_mei.mp3',
      'ஆய்த எழுத்து': 'assets/audio/tamil/quizzes/cat_aytham.mp3',
      'உயிர்மெய் எழுத்துகள்': 'assets/audio/tamil/quizzes/cat_uyirmei.mp3',
      'வாசிப்பு வினாடி வினா': 'assets/audio/tamil/quizzes/cat_reading.mp3',

      // Uyir Questions
      'தமிழ் உயிர் எழுத்துகள் மொத்தம் எத்தனை?': 'assets/audio/tamil/quizzes/quiz_uyir_1.mp3',
      '"அ" எழுத்தில் தொடங்கும் சொல் எது?': 'assets/audio/tamil/quizzes/quiz_uyir_2.mp3',
      'அ எழுத்தில் தொடங்கும் சொல் எது?': 'assets/audio/tamil/quizzes/quiz_uyir_2.mp3',
      'இவற்றுள் நெடில் எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_uyir_3.mp3',
      'கடைசி உயிர் எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_uyir_4.mp3',

      // Mei Questions
      'தமிழ் மெய் எழுத்துகள் மொத்தம் எத்தனை?': 'assets/audio/tamil/quizzes/quiz_mei_1.mp3',
      'மெய் எழுத்துகளை எவ்வாறு அடையாளம் காணலாம்?': 'assets/audio/tamil/quizzes/quiz_mei_2.mp3',
      '"கண்" என்ற சொல்லில் உள்ள மெய் எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_mei_3.mp3',
      'கண் என்ற சொல்லில் உள்ள மெய் எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_mei_3.mp3',
      'தமிழ் மொழிக்கே உரிய சிறப்பு மெய் எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_mei_4.mp3',

      // Aytham Questions
      'ஆய்த எழுத்து எது?': 'assets/audio/tamil/quizzes/quiz_aytham_1.mp3',
      'ஆய்த எழுத்தில் எத்தனை புள்ளிகள் உள்ளன?': 'assets/audio/tamil/quizzes/quiz_aytham_2.mp3',
      'ஆய்த எழுத்து இடம்பெறும் சொல் எது?': 'assets/audio/tamil/quizzes/quiz_aytham_3.mp3',

      // Uyirmei Questions (distinct letter enunciation)
      'க் + அ = என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_1.mp3',
      'க் கூட்டல் அ என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_1.mp3',
      'க், கூட்டல், அ, என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_1.mp3',
      'மொத்த உயிர்மெய் எழுத்துகள் எத்தனை?': 'assets/audio/tamil/quizzes/quiz_uyirmei_2.mp3',
      'க் + ஆ = என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_3.mp3',
      'க் கூட்டல் ஆ என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_3.mp3',
      'க், கூட்டல், ஆ, என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_3.mp3',
      'ம + அ = என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_4.mp3',
      'ம் + அ = என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_4.mp3',
      'ம் கூட்டல் அ என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_4.mp3',
      'ம், கூட்டல், அ, என்ன எழுத்து?': 'assets/audio/tamil/quizzes/quiz_uyirmei_4.mp3',

      // Reading Questions
      '"முயலும் ஆமையும்" கதையில் பந்தயத்தில் வென்றது யார்?': 'assets/audio/tamil/quizzes/quiz_reading_1.mp3',
      'முயலும் ஆமையும் கதையில் பந்தயத்தில் வென்றது யார்?': 'assets/audio/tamil/quizzes/quiz_reading_1.mp3',
      'முயல் ஏன் பந்தயத்தில் தோற்றது?': 'assets/audio/tamil/quizzes/quiz_reading_2.mp3',
      'இக்கதை நமக்குக் கற்றுத்தரும் நீதி என்ன?': 'assets/audio/tamil/quizzes/quiz_reading_3.mp3',

      // Quiz Answer Choice Option Audios (Mei Q2)
      'மேலே புள்ளி இருக்கும்': 'assets/audio/tamil/quizzes/opt_mei_2_1.mp3',
      'கீழே கோடு இருக்கும்': 'assets/audio/tamil/quizzes/opt_mei_2_2.mp3',
      'சுழி இருக்கும்': 'assets/audio/tamil/quizzes/opt_mei_2_3.mp3',
      'வட்டமாக இருக்கும்': 'assets/audio/tamil/quizzes/opt_mei_2_4.mp3',

      // Quiz Answer Choice Option Audios (Reading Q2)
      'பயந்துவிட்டது': 'assets/audio/tamil/quizzes/opt_reading_2_1.mp3',
      'தூங்கிவிட்டது': 'assets/audio/tamil/quizzes/opt_reading_2_2.mp3',
      'வழி தவறியது': 'assets/audio/tamil/quizzes/opt_reading_2_3.mp3',
      'கால் வலித்தது': 'assets/audio/tamil/quizzes/opt_reading_2_4.mp3',

      // Quiz Answer Choice Option Audios (Reading Q3)
      'வேகமே சிறந்தது': 'assets/audio/tamil/quizzes/opt_reading_3_1.mp3',
      'விடாமுயற்சி வெற்றி தரும்': 'assets/audio/tamil/quizzes/opt_reading_3_2.mp3',
      'தூங்குவது நல்லது': 'assets/audio/tamil/quizzes/opt_reading_3_3.mp3',
      'பந்தயம் கூடாது': 'assets/audio/tamil/quizzes/opt_reading_3_4.mp3',

      // Quiz Answer Choice Option Audios (Words)
      'நரி': 'assets/audio/tamil/quizzes/opt_nari.mp3',
      'மான்': 'assets/audio/tamil/quizzes/opt_maan.mp3',
      'முயல்': 'assets/audio/tamil/quizzes/opt_muyal.mp3',
      'ஆமை': 'assets/audio/tamil/quizzes/opt_aamai.mp3',

      // Quiz Answer Choice Option Audios (Numbers)
      '1': 'assets/audio/tamil/quizzes/opt_num_1.mp3',
      'ஒன்று': 'assets/audio/tamil/quizzes/opt_num_1.mp3',
      '2': 'assets/audio/tamil/quizzes/opt_num_2.mp3',
      'இரண்டு': 'assets/audio/tamil/quizzes/opt_num_2.mp3',
      '3': 'assets/audio/tamil/quizzes/opt_num_3.mp3',
      'மூன்று': 'assets/audio/tamil/quizzes/opt_num_3.mp3',
      '4': 'assets/audio/tamil/quizzes/opt_num_4.mp3',
      'நான்கு': 'assets/audio/tamil/quizzes/opt_num_4.mp3',
      '10': 'assets/audio/tamil/quizzes/opt_num_10.mp3',
      'பத்து': 'assets/audio/tamil/quizzes/opt_num_10.mp3',
      '12': 'assets/audio/tamil/quizzes/opt_num_12.mp3',
      'பன்னிரண்டு': 'assets/audio/tamil/quizzes/opt_num_12.mp3',
      '18': 'assets/audio/tamil/quizzes/opt_num_18.mp3',
      'பதினெட்டு': 'assets/audio/tamil/quizzes/opt_num_18.mp3',
      '24': 'assets/audio/tamil/quizzes/opt_num_24.mp3',
      'இருபத்து நான்கு': 'assets/audio/tamil/quizzes/opt_num_24.mp3',
      '30': 'assets/audio/tamil/quizzes/opt_num_30.mp3',
      'முப்பது': 'assets/audio/tamil/quizzes/opt_num_30.mp3',
      '100': 'assets/audio/tamil/quizzes/opt_num_100.mp3',
      'நூறு': 'assets/audio/tamil/quizzes/opt_num_100.mp3',
      '216': 'assets/audio/tamil/quizzes/opt_num_216.mp3',
      'இருநூற்றுப் பதினாறு': 'assets/audio/tamil/quizzes/opt_num_216.mp3',

      // Question ID shortcuts
      'qu_1': 'assets/audio/tamil/quizzes/quiz_uyir_1.mp3',
      'qu_2': 'assets/audio/tamil/quizzes/quiz_uyir_2.mp3',
      'qu_3': 'assets/audio/tamil/quizzes/quiz_uyir_3.mp3',
      'qu_4': 'assets/audio/tamil/quizzes/quiz_uyir_4.mp3',
      'qm_1': 'assets/audio/tamil/quizzes/quiz_mei_1.mp3',
      'qm_2': 'assets/audio/tamil/quizzes/quiz_mei_2.mp3',
      'qm_3': 'assets/audio/tamil/quizzes/quiz_mei_3.mp3',
      'qm_4': 'assets/audio/tamil/quizzes/quiz_mei_4.mp3',
      'qa_1': 'assets/audio/tamil/quizzes/quiz_aytham_1.mp3',
      'qa_2': 'assets/audio/tamil/quizzes/quiz_aytham_2.mp3',
      'qa_3': 'assets/audio/tamil/quizzes/quiz_aytham_3.mp3',
      'qum_1': 'assets/audio/tamil/quizzes/quiz_uyirmei_1.mp3',
      'qum_2': 'assets/audio/tamil/quizzes/quiz_uyirmei_2.mp3',
      'qum_3': 'assets/audio/tamil/quizzes/quiz_uyirmei_3.mp3',
      'qum_4': 'assets/audio/tamil/quizzes/quiz_uyirmei_4.mp3',
      'qr_1': 'assets/audio/tamil/quizzes/quiz_reading_1.mp3',
      'qr_2': 'assets/audio/tamil/quizzes/quiz_reading_2.mp3',
      'qr_3': 'assets/audio/tamil/quizzes/quiz_reading_3.mp3',
    };
    for (final entry in quizMappings.entries) {
      map[entry.key] = entry.value;
    }

    return map;
  }

  static final Map<String, String> _reverseAudioMapping = _buildReverseAudioMapping();

  static Map<String, String> _buildReverseAudioMapping() {
    final reverse = <String, String>{};

    for (final entry in _audioMapping.entries) {
      final text = entry.key;
      final path = entry.value;
      reverse[path] = text;
      if (path.startsWith('assets/')) {
        reverse[path.substring(7)] = text;
      }
    }

    // Direct and legacy sound path reverse mappings
    const legacySounds = <String, String>{
      // Uyir
      'assets/sounds/uyir/uyir_a.mp3': 'அ',
      'assets/sounds/uyir/uyir_aa.mp3': 'ஆ',
      'assets/sounds/uyir/uyir_i.mp3': 'இ',
      'assets/sounds/uyir/uyir_ee.mp3': 'ஈ',
      'assets/sounds/uyir/uyir_u.mp3': 'உ',
      'assets/sounds/uyir/uyir_oo.mp3': 'ஊ',
      'assets/sounds/uyir/uyir_e.mp3': 'எ',
      'assets/sounds/uyir/uyir_ae.mp3': 'ஏ',
      'assets/sounds/uyir/uyir_ai.mp3': 'ஐ',
      'assets/sounds/uyir/uyir_o.mp3': 'ஒ',
      'assets/sounds/uyir/uyir_oo_long.mp3': 'ஓ',
      'assets/sounds/uyir/uyir_au.mp3': 'ஔ',
      'assets/audio/tamil/uyir/அ.mp3': 'அ',

      // Mei
      'assets/sounds/mei/mei_ik.mp3': 'க்',
      'assets/sounds/mei/mei_ing.mp3': 'ங்',
      'assets/sounds/mei/mei_ich.mp3': 'ச்',
      'assets/sounds/mei/mei_inj.mp3': 'ஞ்',
      'assets/sounds/mei/mei_it.mp3': 'ட்',
      'assets/sounds/mei/mei_inn.mp3': 'ண்',
      'assets/sounds/mei/mei_ith.mp3': 'த்',
      'assets/sounds/mei/mei_inth.mp3': 'ந்',
      'assets/sounds/mei/mei_ip.mp3': 'ப்',
      'assets/sounds/mei/mei_im.mp3': 'ம்',
      'assets/sounds/mei/mei_iy.mp3': 'ய்',
      'assets/sounds/mei/mei_ir.mp3': 'ர்',
      'assets/sounds/mei/mei_il.mp3': 'ல்',
      'assets/sounds/mei/mei_iv.mp3': 'வ்',
      'assets/sounds/mei/mei_izh.mp3': 'ழ்',
      'assets/sounds/mei/mei_ill.mp3': 'ள்',
      'assets/sounds/mei/mei_irr.mp3': 'ற்',
      'assets/sounds/mei/mei_in.mp3': 'ன்',

      // Aytham
      'assets/sounds/aytham_ஃ.mp3': 'ஃ',
      'assets/audio/tamil/aytham/aytham_01_ak.mp3': 'ஃ',
    };

    for (final entry in legacySounds.entries) {
      reverse[entry.key] = entry.value;
      if (entry.key.startsWith('assets/')) {
        reverse[entry.key.substring(7)] = entry.value;
      }
    }

    return reverse;
  }

  /// Checks whether an asset is physically available in the app bundle or local file tree.
  Future<bool> isAssetAvailable(String path) async {
    final clean = path.trim();
    final withPrefix = clean.startsWith('assets/') ? clean : 'assets/$clean';
    try {
      final byteData = await rootBundle.load(withPrefix);
      return byteData.lengthInBytes > 0;
    } catch (_) {
      try {
        final withoutPrefix = clean.startsWith('assets/') ? clean.substring(7) : clean;
        final byteData = await rootBundle.load(withoutPrefix);
        return byteData.lengthInBytes > 0;
      } catch (_) {
        try {
          final file = File(withPrefix);
          if (file.existsSync()) return true;
        } catch (_) {}
        return false;
      }
    }
  }

  /// Safely resolves any string or asset path to pure spoken Tamil text.
  /// Strictly prevents speaking file paths, URLs, or non-Tamil strings.
  static String resolveTamilText(String input, {String? fallback}) {
    final trimmed = input.trim();
    // If input is already pure Tamil or plain text (no paths, URLs, or extensions)
    if (!trimmed.startsWith('assets/') &&
        !trimmed.contains('/') &&
        !trimmed.contains(r'\') &&
        !trimmed.endsWith('.mp3') &&
        !trimmed.endsWith('.wav') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Try reverse mapping lookup
    if (_reverseAudioMapping.containsKey(trimmed)) {
      return _reverseAudioMapping[trimmed]!;
    }
    final withPrefix = trimmed.startsWith('assets/') ? trimmed : 'assets/$trimmed';
    if (_reverseAudioMapping.containsKey(withPrefix)) {
      return _reverseAudioMapping[withPrefix]!;
    }
    final withoutPrefix = trimmed.startsWith('assets/') ? trimmed.substring(7) : trimmed;
    if (_reverseAudioMapping.containsKey(withoutPrefix)) {
      return _reverseAudioMapping[withoutPrefix]!;
    }

    // Use fallback if valid pure text
    if (fallback != null && fallback.trim().isNotEmpty) {
      final fb = fallback.trim();
      if (!fb.contains('/') && !fb.contains(r'\') && !fb.endsWith('.mp3')) {
        return fb;
      }
    }

    return '';
  }

  Future<bool> _playAsset(String path) async {
    try {
      final clean = path.trim();
      final withPrefix = clean.startsWith('assets/') ? clean : 'assets/$clean';
      if (!await isAssetAvailable(path)) {
        final localFile = File(withPrefix);
        if (localFile.existsSync()) {
          await player.stop();
          await player.setVolume(1.0);
          await player.play(DeviceFileSource(localFile.absolute.path), volume: 1.0);
          return true;
        }
        return false;
      }
      final cleanPath = path.startsWith('assets/') ? path.substring(7) : path;
      await player.stop();
      await player.setVolume(1.0);
      try {
        await player.play(AssetSource(cleanPath), volume: 1.0);
        return true;
      } catch (assetErr) {
        final localFile = File(withPrefix);
        if (localFile.existsSync()) {
          await player.play(DeviceFileSource(localFile.absolute.path), volume: 1.0);
          return true;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[TamilAudioService] Asset playback failed for $path: $e');
      return false;
    }
  }

  /// Clean and extract pure spoken Tamil text from a string, removing English glosses like (Forest)
  static String extractSpokenTamilText(String input) {
    var cleaned = input.trim();
    // Remove bracketed content like (Forest), (Rabbit), etc.
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    // If mixed with English text, extract pure Tamil characters
    final tamilOnly = cleaned.replaceAll(RegExp(r'[a-zA-Z0-9_\-\:\|\/\\]+'), ' ').trim();
    if (tamilOnly.isNotEmpty) {
      return tamilOnly.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return cleaned;
  }

  /// Maps any Tamil text or key to its relative audio asset path
  static String? getAudioPath(String text) {
    final trimmed = text.trim();
    if (_audioMapping.containsKey(trimmed)) {
      return _audioMapping[trimmed];
    }
    final clean = extractSpokenTamilText(trimmed);
    if (clean.isNotEmpty && _audioMapping.containsKey(clean)) {
      return _audioMapping[clean];
    }
    // Check if input is already a valid asset path
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }
    // Check hex-encoded word asset format
    if (clean.isNotEmpty) {
      final hex = utf8.encode(clean).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final hexPath = 'assets/audio/tamil/words/word_$hex.mp3';
      return hexPath;
    }
    return null;
  }

  /// Displays an attractive kid-friendly floating audio indicator with speaker icon
  static void showAudioIndicator(
    BuildContext context, {
    required String text,
    String? subtext,
  }) {
    if (!context.mounted) return;
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: const Color(0xFF2B2D42).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3F4259),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFFFFD166),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (subtext != null && subtext.isNotEmpty && subtext != text)
                      ? 'ஒலி: $text ($subtext)'
                      : 'ஒலி: $text',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TamilAudioService] showAudioIndicator notice: $e');
    }
  }

  Future<bool> _fetchAndPlayOnlineAudio(String text) async {
    try {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return false;

      final tempFile = File('${Directory.systemTemp.path}/ta_${trimmed.hashCode}.mp3');

      if (await tempFile.exists() && (await tempFile.length()) > 0) {
        await player.stop();
        await player.setVolume(1.0);
        await player.play(DeviceFileSource(tempFile.path), volume: 1.0);
        debugPrint('[TamilAudioService] Playing cached audio file: "${tempFile.path}"');
        return true;
      }

      // 1. Try local backend audio synthesis endpoint (ElevenLabs/Node backend)
      try {
        final backendUri = Uri.parse('${ApiConfig.baseUrl}/audio/synthesize');
        final backendRes = await http.post(
          backendUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': trimmed, 'category': 'sentences'}),
        ).timeout(const Duration(seconds: 2));

        if (backendRes.statusCode == 200) {
          final data = jsonDecode(backendRes.body);
          if (data != null && data['data'] != null && data['data']['audioPath'] != null) {
            final assetPath = data['data']['audioPath'].toString();
            if (await isAssetAvailable(assetPath)) {
              if (await _playAsset(assetPath)) return true;
            }
          }
        }
      } catch (_) {}

      // 2. Try high quality Google TTS endpoints
      final urls = [
        'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(trimmed)}&tl=ta&client=tw-ob',
        'https://translate.googleapis.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(trimmed)}&tl=ta&client=gtx',
        'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(trimmed)}&tl=ta&client=dict-chrome-ex',
      ];

      for (final url in urls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
              'Accept': 'audio/mpeg, audio/*; q=0.9, */*; q=0.8',
              'Referer': 'https://translate.google.com/',
            },
          ).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await tempFile.writeAsBytes(response.bodyBytes);
            await player.stop();
            await player.setVolume(1.0);
            await player.play(DeviceFileSource(tempFile.path), volume: 1.0);
            debugPrint('[TamilAudioService] Saved and playing Tamil speech from: "${tempFile.path}" (${response.bodyBytes.length} bytes)');
            return true;
          }
        } catch (e) {
          debugPrint('[TamilAudioService] URL attempt failed ($url): $e');
        }
      }
    } catch (e) {
      debugPrint('[TamilAudioService] Online speech stream exception: $e');
    }
    return false;
  }

  /// Main Centralized Method: Resolves and plays audio for any Tamil text.
  /// 1. Plays pre-recorded Tamil audio assets
  /// 2. Plays remote URLs (if applicable)
  /// 3. Streams dynamic Tamil speech audio
  /// 4. Fallback to device TTS
  Future<void> playTamilAudio(String? text, {String? fallbackTamilText}) async {
    if (_isMuted || text == null || text.trim().isEmpty) return;

    final trimmed = text.trim();

    // 1. Remote URLs (backend streaming or remote audio)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        await player.stop();
        await player.setVolume(1.0);
        await player.play(UrlSource(trimmed), volume: 1.0);
        return;
      } catch (e) {
        debugPrint('[TamilAudioService] UrlSource playback failed for $trimmed: $e');
      }
    }

    // 2. Extract clean spoken Tamil text
    final spokenText = extractSpokenTamilText(trimmed);
    final targetText = spokenText.isNotEmpty ? spokenText : trimmed;

    // 3. Direct or candidate asset path lookup
    final isPath = trimmed.startsWith('assets/') || trimmed.endsWith('.mp3');
    final assetPath = isPath ? trimmed : getAudioPath(targetText);

    // 4. Play bundled asset if present
    if (assetPath != null && await isAssetAvailable(assetPath)) {
      final played = await _playAsset(assetPath);
      if (played) return;
    }

    // 5. Try candidate letter audio paths (e.g., 'அ')
    final candidates = _getLetterCandidatePaths(targetText);
    for (final candidate in candidates) {
      if (await isAssetAvailable(candidate)) {
        final played = await _playAsset(candidate);
        if (played) return;
      }
    }

    // 6. Try fallback text if provided
    if (fallbackTamilText != null && fallbackTamilText.trim().isNotEmpty) {
      final fbClean = extractSpokenTamilText(fallbackTamilText);
      final fbPath = getAudioPath(fbClean);
      if (fbPath != null && await isAssetAvailable(fbPath)) {
        final played = await _playAsset(fbPath);
        if (played) return;
      }
    }

    // 7. Play crystal-clear Tamil speech via high quality online stream
    final playedOnline = await _fetchAndPlayOnlineAudio(targetText);
    if (playedOnline) return;

    // 8. Fallback to device TTS engine (for mobile devices)
    await TamilTtsService.instance.speakText(targetText);

    // 9. Windows native OneCore voice fallback
    if (Platform.isWindows) {
      await _speakWindowsNativeTamil(targetText);
    }
  }

  Future<void> _speakWindowsNativeTamil(String text) async {
    try {
      final safeText = text.replaceAll('"', '""').replaceAll("'", "''");
      final script = '''
Add-Type -AssemblyName System.Speech;
[Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media, ContentType=WindowsRuntime] | Out-Null;
\$synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer;
\$taVoice = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices | Where-Object { \$_.Language -like "ta*" };
if (\$taVoice) {
    \$synth.Voice = \$taVoice;
    \$stream = \$synth.SynthesizeTextToStreamAsync("$safeText").GetAwaiter().GetResult();
    \$fileStream = [System.IO.File]::Create("\$([System.IO.Path]::GetTempPath())tamil_winrt.wav");
    \$stream.AsStreamForRead().CopyTo(\$fileStream);
    \$fileStream.Close();
    (New-Object System.Media.SoundPlayer("\$([System.IO.Path]::GetTempPath())tamil_winrt.wav")).PlaySync();
}
''';
      await Process.run('powershell', ['-WindowStyle', 'Hidden', '-Command', script]);
    } catch (e) {
      debugPrint('[TamilAudioService] Windows native speech error: $e');
    }
  }

  /// Convenience method matching existing AudioService signature
  /// Plays the authentic native Tamil pronunciation audio for the given letter.
  Future<void> playLetterSound(
    BuildContext context, {
    required String letter,
    String? word,
    String? audioPath,
    bool showIndicator = true,
  }) async {
    if (_isMuted) return;

    if (showIndicator && context.mounted) {
      showAudioIndicator(
        context,
        text: letter,
        subtext: word,
      );
    }

    // 1. If explicit audioPath provided and available, play it
    if (audioPath != null && audioPath.trim().isNotEmpty && await isAssetAvailable(audioPath)) {
      final played = await _playAsset(audioPath);
      if (played) return;
    }

    // 2. Check canonical asset for this letter
    final letterAsset = getAudioPath(letter);
    if (letterAsset != null && await isAssetAvailable(letterAsset)) {
      final played = await _playAsset(letterAsset);
      if (played) return;
    }

    // 3. Check fallback candidate paths for letter 'அ' and others
    final candidates = _getLetterCandidatePaths(letter);
    for (final candidate in candidates) {
      if (await isAssetAvailable(candidate)) {
        final played = await _playAsset(candidate);
        if (played) return;
      }
    }

    // 4. Seamless fallback for letters & words
    await playTamilAudio(letter);
  }

  static List<String> _getLetterCandidatePaths(String text) {
    final t = text.trim();
    if (t == '+' || t == 'கூட்டல்' || t == 'plus') {
      return const [
        'assets/audio/tamil/plus.mp3',
        'assets/sounds/plus.mp3',
      ];
    }
    if (t == 'அ' || t == 'uyir_1' || t == 'uyir_a' || t == 'uyir_01_a') {
      return const [
        'assets/sounds/uyir/uyir_a.mp3',
        'assets/sounds/uyir/uyir_01_a.mp3',
        'assets/audio/tamil/uyir/uyir_01_a.mp3',
        'assets/sounds/uyir/அ.mp3',
      ];
    }
    if (t == 'ஃ' || t.toLowerCase() == 'ak' || t == 'அக்கு') {
      return const [
        'assets/audio/tamil/aytham/aytham_01_ak.mp3',
        'assets/sounds/aytham_ஃ.mp3',
      ];
    }
    return [
      'assets/sounds/mei/$t.mp3',
      'assets/sounds/uyirmei/$t.mp3',
    ];
  }

  /// Plays pronunciation for the '+' (கூட்டல்) operator symbol
  Future<void> playPlusSound(BuildContext context, {bool showIndicator = true}) async {
    if (_isMuted) return;

    if (showIndicator && context.mounted) {
      showAudioIndicator(
        context,
        text: '+',
        subtext: 'கூட்டல்',
      );
    }

    const candidatePaths = [
      'assets/audio/tamil/plus.mp3',
      'assets/sounds/plus.mp3',
    ];

    for (final path in candidatePaths) {
      if (await isAssetAvailable(path)) {
        final played = await _playAsset(path);
        if (played) return;
      }
    }

    await playTamilAudio('கூட்டல்');
  }

  /// Convenience method for speaking any text
  Future<void> speakText(String? text, {String? fallbackTamilText}) async {
    await playTamilAudio(text, fallbackTamilText: fallbackTamilText);
  }

  /// Stops any playing audio
  Future<void> stopAll() async {
    try {
      await _player?.stop();
      await TamilTtsService.instance.stop();
    } catch (e) {
      debugPrint('[TamilAudioService] stopAll: $e');
    }
  }

  /// Plays cheerful success feedback sound effect
  Future<void> playSuccessFeedback(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Plays star award sound effect
  Future<void> playStarReward(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Plays gentle retry effect
  Future<void> playRetryFeedback(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
