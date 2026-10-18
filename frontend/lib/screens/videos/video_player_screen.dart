import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart';
import '../../models/video_model.dart';
import '../../services/api_config.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/celebration_dialog.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  final ProgressService progressService;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.progressService,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasCompleted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isLandscape = true;
  bool _isCoverMode = false;

  @override
  void initState() {
    super.initState();
    // Request horizontal landscape orientation for cinema view
    _setLandscape();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _setPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _restoreSystemSettings() {
    _setPortrait();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      _setLandscape();
    } else {
      _setPortrait();
    }
  }

  void _toggleFitMode() {
    setState(() {
      _isCoverMode = !_isCoverMode;
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _restoreSystemSettings();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    if (_controller != null && _controller!.value.isPlaying) {
      _hideControlsTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted && _controller != null && _controller!.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onTapVideoCanvas() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _controller != null && _controller!.value.isPlaying) {
      _startHideTimer();
    } else if (!_showControls) {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    if (!kIsWeb && Platform.isWindows) {
      WindowsVideoPlayer.registerWith();
    }

    final rawUrl = widget.video.videoUrl;
    final resolvedUrl = ApiConfig.resolveMediaUrl(rawUrl);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = LanguageService.instance.isEnglish
            ? 'Video URL not found.'
            : 'காணொளி முகவரி கிடைக்கவில்லை.';
      });
      return;
    }

    try {
      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      } else {
        _controller = VideoPlayerController.asset(resolvedUrl);
      }

      await _controller!.initialize();
      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showControls = true;
        });
        _controller!.play();
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = LanguageService.instance.isEnglish
              ? 'Could not play video: $e'
              : 'காணொளியை இயக்க முடியவில்லை: $e';
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration > Duration.zero && position >= duration && !_hasCompleted) {
      _hasCompleted = true;
      _completeVideo();
    }

    setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        if (_controller!.value.position >= _controller!.value.duration) {
          _controller!.seekTo(Duration.zero);
        }
        _controller!.play();
        _showControls = true;
        _startHideTimer();
      }
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final total = _controller!.value.duration;
    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > total) {
      _controller!.seekTo(total);
    } else {
      _controller!.seekTo(target);
    }
    setState(() {
      _showControls = true;
    });
    _startHideTimer();
  }

  void _completeVideo() {
    widget.progressService.addStars(2);
    final isEn = LanguageService.instance.isEnglish;
    CelebrationDialog.show(
      context,
      title: isEn ? 'Video Completed! 🎉' : 'காணொளி முடிந்தது! 🎉',
      message: isEn
          ? 'Great job watching the lesson! You earned 2 stars!'
          : 'காணொளியைப் பார்த்து மகிழ்ந்ததற்கு வாழ்த்துகள்! உங்களுக்கு 2 நட்சத்திரங்கள் கிடைத்துள்ளன!',
      starsEarned: 2,
      buttonText: isEn ? 'Continue' : 'தொடரலாம்',
      onContinue: () {
        _restoreSystemSettings();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final isPlaying = _controller != null && _controller!.value.isPlaying;
    final shouldShowControls = _showControls || !isPlaying;
    final isEn = LanguageService.instance.isEnglish;

    final mediaQuery = MediaQuery.of(context);
    final isDevicePortrait = mediaQuery.orientation == Orientation.portrait;
    // Rotate 90 degrees if user requests landscape full screen, but device/window is currently vertical portrait
    final shouldRotate = _isLandscape && isDevicePortrait;

    Widget playerBody = SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // 1. Fullscreen Video Surface
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapVideoCanvas,
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Center(
                    child: _isCoverMode
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: (_controller!.value.size.width > 0)
                                    ? _controller!.value.size.width
                                    : 1280,
                                height: (_controller!.value.size.height > 0)
                                    ? _controller!.value.size.height
                                    : 720,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          )
                        : AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio > 0
                                ? _controller!.value.aspectRatio
                                : 16 / 9,
                            child: VideoPlayer(_controller!),
                          ),
                  ),
                ),
              ),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 54, color: Colors.amberAccent),
                    const SizedBox(height: 12),
                    Text(
                      isEn ? 'Could not load video' : 'காணொளியை ஏற்ற முடியவில்லை',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage ?? (isEn ? 'Please check your connection.' : 'இணைய இணைப்பை சரிபார்க்கவும்.'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _initializePlayer,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(isEn ? 'Retry' : 'மீண்டும் முயற்சிக்கவும்'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: AppColors.starGold, strokeWidth: 4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Preparing video...' : 'காணொளி தயாராகிறது...',
                    style: const TextStyle(
                      color: AppColors.sunnyYellow,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 2. Buffering Spinner
          if (_isInitialized && _controller != null && _controller!.value.isBuffering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.starGold, strokeWidth: 4),
            ),

          // 3. Top Gradient & Top Header Controls Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: shouldShowControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !shouldShowControls,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        // Back Button
                        InkWell(
                          onTap: () {
                            _restoreSystemSettings();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                v.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 6),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      v.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      isEn ? 'Cinema Mode' : 'திரையரங்கம்',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Fit Mode Toggle Button (Fit / Fill)
                        InkWell(
                          onTap: _toggleFitMode,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isCoverMode
                                  ? AppColors.primary.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCoverMode ? Icons.fit_screen_rounded : Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _isCoverMode ? (isEn ? 'Fit' : 'பொருத்து') : (isEn ? 'Fill' : 'நிரப்பு'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Orientation Toggle Button (Landscape / Portrait)
                        InkWell(
                          onTap: _toggleOrientation,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLandscape
                                      ? Icons.screen_lock_landscape_rounded
                                      : Icons.screen_lock_portrait_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _isLandscape ? (isEn ? 'Land' : 'கிடைமட்டம்') : (isEn ? 'Port' : 'செங்குத்து'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Stars Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.starGold, size: 16),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.progressService.stars}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Center Play / Pause & Skip Buttons
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: shouldShowControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !shouldShowControls,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rewind 10s
                        InkWell(
                          onTap: () => _seekRelative(-10),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.replay_10_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 26),

                        // Main Play/Pause Button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 26),

                        // Forward 10s
                        InkWell(
                          onTap: () => _seekRelative(10),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.forward_10_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Bottom Gradient & Scrubber Controls Overlay
          if (_isInitialized && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: shouldShowControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !shouldShowControls,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scrubber Row
                          Row(
                            children: [
                              Text(
                                _formatDuration(_controller!.value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    trackHeight: 4.5,
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.starGold,
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  ),
                                  child: Slider(
                                    value: _controller!.value.duration.inMilliseconds > 0
                                        ? (_controller!.value.position.inMilliseconds /
                                                _controller!.value.duration.inMilliseconds)
                                            .clamp(0.0, 1.0)
                                        : 0.0,
                                    onChangeStart: (_) {
                                      _hideControlsTimer?.cancel();
                                    },
                                    onChanged: (val) {
                                      final seekMs =
                                          (_controller!.value.duration.inMilliseconds * val).toInt();
                                      _controller!.seekTo(Duration(milliseconds: seekMs));
                                    },
                                    onChangeEnd: (_) {
                                      if (_controller!.value.isPlaying) {
                                        _startHideTimer();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(_controller!.value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Bottom Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Replay button
                              TextButton.icon(
                                onPressed: () {
                                  _controller!.seekTo(Duration.zero);
                                  _controller!.play();
                                  _startHideTimer();
                                },
                                icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 17),
                                label: Text(
                                  isEn ? 'Replay' : 'மீண்டும் பார்',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),

                              // Finish Video button (+2 stars)
                              ElevatedButton.icon(
                                onPressed: _completeVideo,
                                icon: const Icon(Icons.star_rounded, color: Colors.white, size: 17),
                                label: Text(
                                  isEn ? 'Finish (+2 ⭐)' : 'முடித்தேன் (+2 ⭐)',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _restoreSystemSettings();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: shouldRotate
            ? RotatedBox(
                quarterTurns: 1,
                child: playerBody,
              )
            : playerBody,
      ),
    );
  }
}
