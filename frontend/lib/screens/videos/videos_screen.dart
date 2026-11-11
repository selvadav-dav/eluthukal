import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'video_player_screen.dart';

const List<String> kUyirLetters = [
  'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ'
];

const List<String> kMeiLetters = [
  'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்', 'த்', 'ந்', 'ப்', 'ம்',
  'ய்', 'ர்', 'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்'
];

class VideosScreen extends StatefulWidget {
  final ProgressService progressService;

  const VideosScreen({super.key, required this.progressService});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'uyir', 'mei', 'others'

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      DataService.instance.clearVideoCache();
      final list = await DataService.instance.getVideoLessons();
      if (mounted) {
        setState(() {
          _videos = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isUyirVideo(VideoItem v) {
    final cat = v.category.trim();
    if (cat == 'உயிர் எழுத்துகள்' || cat == 'உயிர் எழுத்துக்கள்' || cat.toLowerCase() == 'uyir') {
      return true;
    }
    return kUyirLetters.any((l) => v.title.trim() == l || v.title.trim().startsWith('$l '));
  }

  bool _isMeiVideo(VideoItem v) {
    final cat = v.category.trim();
    if (cat == 'மெய் எழுத்துகள்' || cat == 'மெய் எழுத்துக்கள்' || cat.toLowerCase() == 'mei') {
      return true;
    }
    return kMeiLetters.any((l) => v.title.trim() == l || v.title.trim().startsWith('$l '));
  }

  bool _isAythamVideo(VideoItem v) {
    final cat = v.category.trim().toLowerCase();
    if (cat.contains('ஆய்த') ||
        cat.contains('ஆயுத') ||
        cat.contains('aytham') ||
        cat.contains('ayutham') ||
        cat.contains('ayudha') ||
        cat.contains('ayutha') ||
        cat.contains('ஃ')) {
      return true;
    }
    final title = v.title.trim().toLowerCase();
    return title == 'ஃ' ||
        title.startsWith('ஃ') ||
        title.contains('ஆய்த') ||
        title.contains('ஆயுத') ||
        title.contains('aytham') ||
        title.contains('ayutham') ||
        title.contains('ayudha') ||
        title.contains('ayutha');
  }

  List<VideoItem> get _uyirVideos {
    final list = _videos.where(_isUyirVideo).toList();
    list.sort((a, b) {
      final aLetter = kUyirLetters.indexWhere((l) => a.title.trim() == l || a.title.trim().startsWith('$l '));
      final bLetter = kUyirLetters.indexWhere((l) => b.title.trim() == l || b.title.trim().startsWith('$l '));
      if (aLetter != -1 && bLetter != -1) return aLetter.compareTo(bLetter);
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return list;
  }

  List<VideoItem> get _meiVideos {
    final list = _videos.where(_isMeiVideo).toList();
    list.sort((a, b) {
      final aLetter = kMeiLetters.indexWhere((l) => a.title.trim() == l || a.title.trim().startsWith('$l '));
      final bLetter = kMeiLetters.indexWhere((l) => b.title.trim() == l || b.title.trim().startsWith('$l '));
      if (aLetter != -1 && bLetter != -1) return aLetter.compareTo(bLetter);
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return list;
  }

  List<VideoItem> get _aythamVideos {
    return _videos.where(_isAythamVideo).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uyirList = _uyirVideos;
    final meiList = _meiVideos;
    final aythamList = _aythamVideos;
    final isEn = LanguageService.instance.isEnglish;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.progressService, LanguageService.instance]),
      builder: (context, _) {
        return Scaffold(
          appBar: KidAppBar(
            title: LanguageService.instance.videosHeading,
            starCount: widget.progressService.stars,
            showBack: false,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: RefreshIndicator(
                    onRefresh: _loadVideos,
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        // Hero Card with Mascot
                        _buildHeroBanner(),
                        const SizedBox(height: 16),

                        // Filter Pills
                        _buildFilterChips(uyirList.length, meiList.length, aythamList.length),
                        const SizedBox(height: 18),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else ...[
                          // Section 1: Uyir Letters
                          if (_selectedFilter == 'all' || _selectedFilter == 'uyir') ...[
                            _buildSectionHeader(
                              icon: Icons.auto_awesome_rounded,
                              title: isEn ? 'Vowels Videos (Uyir)' : 'உயிர் எழுத்துகள் காணொளிகள்',
                              countText: '${uyirList.length}/12',
                              subtitle: isEn ? 'Letters lessons from அ to ஔ' : 'அ முதல் ஔ வரையிலான எழுத்துப் பாடங்கள்',
                              badgeColor: AppColors.uyirColor,
                            ),
                            const SizedBox(height: 10),
                            if (uyirList.isEmpty)
                              _buildEmptyCategoryCard(isEn ? 'No vowel videos yet' : 'உயிர் எழுத்துகள் காணொளிகள் எதுவும் இல்லை')
                            else
                              ...uyirList.map((v) => _buildVideoCard(v, isUyir: true)),
                            const SizedBox(height: 24),
                          ],

                          // Section 2: Mei Letters
                          if (_selectedFilter == 'all' || _selectedFilter == 'mei') ...[
                            _buildSectionHeader(
                              icon: Icons.edit_note_rounded,
                              title: isEn ? 'Consonants Videos (Mei)' : 'மெய் எழுத்துகள் காணொளிகள்',
                              countText: '${meiList.length}/18',
                              subtitle: isEn ? 'Letters lessons from க் to ன்' : 'க் முதல் ன் வரையிலான எழுத்துப் பாடங்கள்',
                              badgeColor: AppColors.meiColor,
                            ),
                            const SizedBox(height: 10),
                            if (meiList.isEmpty)
                              _buildMeiPlaceholderCard()
                            else
                              ...meiList.map((v) => _buildVideoCard(v, isMei: true)),
                            const SizedBox(height: 24),
                          ],

                          // Section 3: Aytham Letter (ஃ)
                          if (_selectedFilter == 'all' || _selectedFilter == 'aytham') ...[
                            _buildSectionHeader(
                              icon: Icons.stars_rounded,
                              title: isEn ? 'Aytham Letter Video (ஃ)' : 'ஆய்த எழுத்து காணொளி',
                              countText: '${aythamList.length}/1',
                              subtitle: isEn ? 'Three-dotted unique Tamil letter (ஃ)' : 'முப்புள்ளி கொண்ட தனித்தமிழ் எழுத்து (ஃ)',
                              badgeColor: const Color(0xFF8338EC),
                            ),
                            const SizedBox(height: 10),
                            if (aythamList.isEmpty)
                              _buildAythamPlaceholderCard()
                            else
                              ...aythamList.map((v) => _buildVideoCard(v, isAytham: true)),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    final isEn = LanguageService.instance.isEnglish;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF80CBC4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEn ? '🎬 Video Cinema' : '🎬 காணொளி திரையரங்கம்',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEn ? 'Watch & Learn Together!' : 'பார்த்து கற்றுக்கொள்வோம்!',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    color: const Color(0xFF004D40),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn
                      ? 'Vowels, Consonants & Aytham videos'
                      : 'உயிர், மெய் மற்றும் ஆய்த எழுத்துகள் காணொளிகள்',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00695C),
                  ),
                ),
              ],
            ),
          ),
          const MascotWidget(
            pose: MascotPose.video,
            size: MascotSize.small,
            customHeight: 110,
            showGlow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int uyirCount, int meiCount, int aythamCount) {
    final isEn = LanguageService.instance.isEnglish;
    final filters = [
      {'id': 'all', 'label': isEn ? 'All' : 'அனைத்தும்', 'count': _videos.length},
      {'id': 'uyir', 'label': isEn ? 'Vowels' : 'உயிர் எழுத்துகள்', 'count': uyirCount},
      {'id': 'mei', 'label': isEn ? 'Consonants' : 'மெய் எழுத்துகள்', 'count': meiCount},
      {'id': 'aytham', 'label': isEn ? 'Aytham (ஃ)' : 'ஆய்த எழுத்து', 'count': aythamCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          final id = f['id'] as String;
          final color = id == 'uyir'
              ? AppColors.uyirColor
              : id == 'mei'
                  ? AppColors.meiColor
                  : id == 'aytham'
                      ? const Color(0xFF8338EC)
                      : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = id;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${f['count']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String countText,
    required String subtitle,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        countText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLetterBadge(VideoItem video, {required bool isUyir, required bool isMei, required bool isAytham}) {
    if (isAytham) return 'ஃ';
    if (isUyir) {
      for (final l in kUyirLetters) {
        if (video.title.trim() == l || video.title.trim().startsWith('$l ')) {
          return l;
        }
      }
      for (final l in kUyirLetters) {
        if (video.title.contains(l)) return l;
      }
    }
    if (isMei) {
      for (final l in kMeiLetters) {
        if (video.title.trim() == l || video.title.trim().startsWith('$l ')) {
          return l;
        }
      }
      for (final l in kMeiLetters) {
        if (video.title.contains(l)) return l;
      }
    }
    final emojiClean = video.thumbnailEmoji.replaceAll(RegExp(r'[🎬✍️🅰️⭐\s]'), '').trim();
    if (emojiClean.isNotEmpty) {
      return emojiClean;
    }
    return video.title.trim().split(' ').first;
  }

  Widget _buildVideoCard(VideoItem video, {bool isUyir = false, bool isMei = false, bool isAytham = false}) {
    final themeColor = isUyir
        ? AppColors.uyirColor
        : isMei
            ? AppColors.meiColor
            : isAytham
                ? const Color(0xFF8338EC)
                : AppColors.primary;

    final isLetterTitle = (isUyir && kUyirLetters.contains(video.title.trim())) ||
        (isMei && kMeiLetters.contains(video.title.trim())) ||
        (isAytham && video.title.trim() == 'ஃ');

    final displayTitle = isLetterTitle ? '${video.title} - எழுத்து காணொளி' : video.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                video: video,
                progressService: widget.progressService,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar / Letter Badge Thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUyir
                        ? AppColors.pinkGradient
                        : isMei
                            ? AppColors.blueGradient
                            : isAytham
                                ? const [Color(0xFF8338EC), Color(0xFFB5179E)]
                                : [const Color(0xFF2B2D42), const Color(0xFF4A4E69)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isUyir || isMei || isAytham)
                      Text(
                        _getLetterBadge(video, isUyir: isUyir, isMei: isMei, isAytham: isAytham),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        video.thumbnailEmoji.isNotEmpty ? video.thumbnailEmoji : '🎬',
                        style: const TextStyle(fontSize: 26),
                      ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: themeColor, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            video.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              video.duration.isNotEmpty ? video.duration : '00:15',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayTitle,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: themeColor, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildMeiPlaceholderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.meiColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: AppColors.meiColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'மெய் எழுத்துகள் காணொளிகள் (18)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'நிர்வாகப் பலகையிலிருந்து பதிவேற்றலாம் (Admin Panel Upload)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kMeiLetters.map((l) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.meiColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAythamPlaceholderCard() {
    final isEn = LanguageService.instance.isEnglish;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8338EC).withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFF8338EC), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Aytham Letter Video (ஃ)' : 'ஆய்த எழுத்து காணொளி (ஃ)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isEn
                          ? 'Upload via Admin Panel'
                          : 'நிர்வாகப் பலகையிலிருந்து பதிவேற்றலாம் (Admin Panel Upload)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ஃ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8338EC),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'முப்புள்ளி ஆய்த எழுத்து',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B21A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
