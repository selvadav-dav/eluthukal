import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../data/tamil_letter_outlines.dart';
import '../data/tamil_stroke_data.dart';
import '../models/handwriting_ml_model.dart';
import '../models/letter_stroke_model.dart';
import '../models/writing_practice_model.dart';
import '../services/audio_service.dart';
import '../services/tamil_handwriting_recognition_service.dart';
import '../services/writing_boundary_validator.dart';
import '../services/writing_engine.dart';

enum WritingCanvasMode {
  learn, // ✏️ கற்றுக்கொள்: Step-by-step guided tracing + audio announcement + one-time demo + ML recognition
  practice, // 🎯 பயிற்சி: Independent writing + real ML recognition
}

class WritingCanvas extends StatefulWidget {
  final String letter;
  final WritingCanvasMode mode;
  final Color strokeColor;
  final double strokeWidth;
  final Function(int strokeCount)? onStrokeUpdated;
  final Function(List<List<WritingPoint>> normalizedStrokes)? onStrokesChanged;
  final VoidCallback? onLetterCompleted;
  final ValueChanged<bool>? onDrawingStateChanged;

  const WritingCanvas({
    super.key,
    required this.letter,
    this.mode = WritingCanvasMode.learn,
    this.strokeColor = const Color(0xFF3A86FF),
    this.strokeWidth = 18.0,
    this.onStrokeUpdated,
    this.onStrokesChanged,
    this.onLetterCompleted,
    this.onDrawingStateChanged,
  });

  @override
  WritingCanvasState createState() => WritingCanvasState();
}

class WritingCanvasState extends State<WritingCanvas> with TickerProviderStateMixin {
  Size _canvasSize = Size.zero;

  // Captured handwriting strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Active step index for progressive step-by-step guidance
  int _activeStepIndex = 0;
  int get activeStepIndex {
    try {
      final dynamic idx = _activeStepIndex;
      if (idx is int) return idx;
    } catch (_) {}
    return 0;
  }

  // ML Recognition status
  bool _isRecognizing = false;
  bool get isRecognizing => _isRecognizing;

  // Route & Demo Animation
  AnimationController? _pulseController;
  AnimationController? _demoController;
  bool _isDemoActive = false;
  bool get isDemoActive => _isDemoActive;

  // Learn-mode feedback for a wrongly traced stroke
  int _failedAttempts = 0;
  int _lastCollectedCheckpoints = 0;
  String? _hintText;
  Timer? _hintTimer;

  void _initControllers() {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (_demoController == null) {
      _demoController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      );

      _demoController!.addListener(() {
        if (mounted && _isDemoActive) setState(() {});
      });

      _demoController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // One-time demo completed! Stop cleanly and let the child draw!
          if (mounted) {
            setState(() {
              _isDemoActive = false;
            });
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WritingEngine.activeLetter = widget.letter;
    _activeStepIndex = 0;
    _initControllers();
    TamilHandwritingRecognitionService.instance.initialize().then((_) {
      if (mounted) setState(() {});
    });

    // Auto-introduce Step 1 on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.mode == WritingCanvasMode.learn) {
        playCurrentStepDemo();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    WritingEngine.activeLetter = widget.letter;
    if (oldWidget.letter != widget.letter || oldWidget.mode != widget.mode) {
      _activeStepIndex = 0;
      clearCanvas();
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _pulseController?.dispose();
    _demoController?.dispose();
    super.dispose();
  }

  /// Sets the active step, speaks it, and plays the demo one time
  void setStep(int stepIndex, {bool playDemo = true}) {
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (stepIndex < 0 || stepIndex >= letterData.strokes.length) return;
    setState(() {
      _activeStepIndex = stepIndex;
      _failedAttempts = 0;
    });
    if (playDemo) {
      playCurrentStepDemo();
    }
  }

  /// Speaks the letter writing instruction and plays the animated demo along ALL strokes of the letter
  void playCurrentStepDemo() {
    _initControllers();
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (letterData.strokes.isEmpty) return;

    // 1. Audio Announcement for the letter
    try {
      AudioService.instance.playTamilAudio('${widget.letter} எழுதும் முறை');
    } catch (_) {}

    // 2. Play animated demo ONE TIME along all strokes of the letter
    if (mounted) {
      setState(() {
        _isDemoActive = true;
      });
    }
    final totalDuration = Duration(milliseconds: math.max(2400, 1800 * letterData.strokes.length));
    _demoController?.duration = totalDuration;
    _demoController?.forward(from: 0.0);
  }

  void _stopDemo() {
    if (_isDemoActive) {
      setState(() {
        _isDemoActive = false;
        _demoController?.stop();
      });
    }
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _activeStepIndex = 0;
      _isDemoActive = false;
      _demoController?.stop();
      _failedAttempts = 0;
      _hintText = null;
    });
    widget.onStrokeUpdated?.call(0);
    widget.onStrokesChanged?.call([]);
    if (widget.mode == WritingCanvasMode.learn) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) playCurrentStepDemo();
      });
    }
  }

  int get totalPointsDrawn {
    int total = _strokes.fold(0, (acc, stroke) => acc + stroke.length);
    return total + _currentStroke.length;
  }

  int get strokeCount => _strokes.length + (_currentStroke.isNotEmpty ? 1 : 0);

  bool get hasContent => totalPointsDrawn > 0;

  List<List<WritingPoint>> getNormalizedStrokes() {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return [];

    return _strokes.map((stroke) {
      return stroke.asMap().entries.map((entry) {
        final idx = entry.key;
        final pt = entry.value;
        return WritingPoint(
          x: (pt.dx / _canvasSize.width).clamp(0.0, 1.0),
          y: (pt.dy / _canvasSize.height).clamp(0.0, 1.0),
          isEndOfStroke: idx == stroke.length - 1,
        );
      }).toList();
    }).toList();
  }

  /// Evaluates the drawn strokes using the Real ML Recognition Pipeline
  Future<HandwritingRecognitionResult> evaluateWithML() async {
    final allStrokes = List<List<Offset>>.from(_strokes);
    if (_currentStroke.isNotEmpty) {
      allStrokes.add(List.from(_currentStroke));
    }

    setState(() => _isRecognizing = true);

    final result = await TamilHandwritingRecognitionService.instance.recognizeStrokes(
      expectedLetter: widget.letter,
      userStrokes: allStrokes,
      canvasSize: _canvasSize,
    );

    if (mounted) {
      setState(() {
        _isRecognizing = false;
      });
    }

    return result;
  }

  /// Checks if touch point is on or near the CURRENT ACTIVE STEP's corridor,
  /// and strictly NOT closer to future steps (e.g. step 2 vertical bar or step 3 curl while on step 1)!
  bool _isPointNearActiveStroke(Offset localPos) {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return true;
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (letterData.strokes.isEmpty) return true;

    final curStep = activeStepIndex.clamp(0, letterData.strokes.length - 1);
    final activeStroke = letterData.strokes[curStep];
    final activeDense = WritingEngine.sampleDensePoints(activeStroke, _canvasSize);
    if (activeDense.isEmpty) return true;

    // 1. Calculate minimum distance to active stroke centerline
    double minActiveDist = double.infinity;
    for (final pt in activeDense) {
      final d = (localPos - pt).distance;
      if (d < minActiveDist) minActiveDist = d;
    }

    // Max allowed touch radius from active stroke centerline (~24-28px, matches canal half-width with finger margin)
    final double maxAllowedDist = math.max(WritingEngine.guideRect(_canvasSize).width * 0.07, 24.0);
    if (minActiveDist > maxAllowedDist) {
      return false; // Point is too far from active stroke!
    }

    // 2. Anti-Skip: Check if point is closer to any FUTURE step than to the active step!
    // Prevents drawing on Step 2 or Step 3 while Step 1 is in progress.
    for (int f = curStep + 1; f < letterData.strokes.length; f++) {
      final futureStroke = letterData.strokes[f];
      final futureDense = WritingEngine.sampleDensePoints(futureStroke, _canvasSize);
      for (final fPt in futureDense) {
        final fDist = (localPos - fPt).distance;
        if (fDist < minActiveDist) {
          return false; // Point belongs to a future step, NOT active step!
        }
      }
    }

    return true;
  }

  // Smooth, lag-free Pointer Events
  void _onPointerDown(Offset localPos) {
    if (_isDemoActive) {
      _stopDemo();
    }
    // Learn Mode: Touch MUST be on the active stroke! If touching elsewhere, ignore!
    if (widget.mode == WritingCanvasMode.learn && !_isPointNearActiveStroke(localPos)) {
      _showHint('பச்சை வட்டத்திலிருந்து தொடங்குங்கள்!');
      return;
    }
    _lastCollectedCheckpoints = 0;
    widget.onDrawingStateChanged?.call(true);
    setState(() {
      _currentStroke = [localPos];
    });
  }

  void _onPointerMove(Offset localPos) {
    if (_currentStroke.isEmpty) {
      if (widget.mode == WritingCanvasMode.learn && !_isPointNearActiveStroke(localPos)) {
        return;
      }
      _lastCollectedCheckpoints = 0;
      widget.onDrawingStateChanged?.call(true);
      setState(() {
        _currentStroke = [localPos];
      });
      return;
    }

    // Learn Mode: ignore points dragged outside the active step's path
    if (widget.mode == WritingCanvasMode.learn && !_isPointNearActiveStroke(localPos)) {
      return;
    }

    final last = _currentStroke.last;
    final dx = localPos.dx - last.dx;
    final dy = localPos.dy - last.dy;
    if ((dx * dx + dy * dy) >= 1.0) {
      setState(() {
        _currentStroke.add(localPos);
      });

      // Play cheerful star collection sound when a checkpoint is collected in forward order
      if (widget.mode == WritingCanvasMode.learn) {
        final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
        if (letterData.strokes.isNotEmpty) {
          final cur = activeStepIndex.clamp(0, letterData.strokes.length - 1);
          final count = WritingBoundaryValidator.getCollectedCheckpointsCount(
            userPoints: _currentStroke,
            stroke: letterData.strokes[cur],
            size: _canvasSize,
          );
          if (count > _lastCollectedCheckpoints) {
            _lastCollectedCheckpoints = count;
            try {
              AudioService.instance.playStarReward(context);
            } catch (_) {}
          }
        }
      }
    }
  }

  void _onPointerUp(Offset localPos) {
    _lastCollectedCheckpoints = 0;
    widget.onDrawingStateChanged?.call(false);
    if (_currentStroke.isEmpty) return;

    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);

    setState(() {
      // In learn mode, only append localPos if it is near the active stroke
      final bool posValid = widget.mode != WritingCanvasMode.learn || _isPointNearActiveStroke(localPos);
      if (posValid) {
        if (_currentStroke.length == 1) {
          _currentStroke.add(localPos.translate(0.5, 0.5));
        } else {
          _currentStroke.add(localPos);
        }
      } else if (_currentStroke.length == 1) {
        _currentStroke.add(_currentStroke.first.translate(0.5, 0.5));
      }
      _strokes.add(List.from(_currentStroke));
      _currentStroke.clear();
    });

    widget.onStrokeUpdated?.call(_strokes.length);
    widget.onStrokesChanged?.call(getNormalizedStrokes());

    // In Learn mode: advance only when the stroke starts at the green marker,
    // follows the track in the right direction and reaches the red marker.
    if (widget.mode == WritingCanvasMode.learn && letterData.strokes.isNotEmpty) {
      final curStep = activeStepIndex.clamp(0, letterData.strokes.length - 1);
      final lastStroke = _strokes.isNotEmpty ? _strokes.last : <Offset>[];
      final attempt = WritingBoundaryValidator.checkStrokeAttempt(
        userPoints: lastStroke,
        stroke: letterData.strokes[curStep],
        size: _canvasSize,
      );

      if (!attempt.isCorrect) {
        _rejectStroke(attempt);
        return;
      }

      _showHint(null);
      _failedAttempts = 0;

      // Lock in the completed step as a 100% solid, seamless, full rainbow fill
      final densePts = WritingEngine.sampleDensePoints(letterData.strokes[curStep], _canvasSize);
      if (densePts.isNotEmpty && _strokes.isNotEmpty) {
        setState(() {
          _strokes[_strokes.length - 1] = densePts;
        });
      }
      if (curStep < letterData.strokes.length - 1) {
        // Stroke finished! Give cheerful audio feedback and seamlessly advance to next stroke
        try {
          AudioService.instance.playTamilAudio('அருமை!');
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setStep(curStep + 1, playDemo: false);
          }
        });
      } else {
        // Final step finished! All steps completed!
        try {
          AudioService.instance.playTamilAudio('அருமை! நீங்கள் ${widget.letter} எழுத்தை அழகாக எழுதி முடித்துவிட்டீர்கள்!');
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            widget.onLetterCompleted?.call();
          }
        });
      }
    }
  }

  /// Removes a wrongly traced stroke and tells the child what to fix.
  void _rejectStroke(StrokeAttemptResult attempt) {
    // A tiny accidental touch is ignored silently.
    final silent = attempt.status == StrokeAttemptStatus.tooShort && (_strokes.lastOrNull?.length ?? 0) <= 3;
    setState(() {
      if (_strokes.isNotEmpty) _strokes.removeLast();
    });
    widget.onStrokeUpdated?.call(_strokes.length);
    widget.onStrokesChanged?.call(getNormalizedStrokes());
    if (silent) return;

    _failedAttempts++;
    _showHint(attempt.hint);
    try {
      AudioService.instance.playTamilAudio(attempt.hint);
    } catch (_) {}

    // After repeated mistakes, show the movement again.
    if (_failedAttempts % 2 == 0) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && !_isDemoActive) {
          _isDemoActive = true;
          _demoController?.forward(from: 0.0);
          setState(() {});
        }
      });
    }
  }

  void _showHint(String? text) {
    _hintTimer?.cancel();
    if (!mounted) return;
    setState(() => _hintText = text);
    if (text != null) {
      _hintTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _hintText = null);
      });
    }
  }

  void _onPointerCancel() {
    _lastCollectedCheckpoints = 0;
    widget.onDrawingStateChanged?.call(false);
    if (_currentStroke.isNotEmpty) {
      setState(() {
        if (widget.mode != WritingCanvasMode.learn) {
          _strokes.add(List.from(_currentStroke));
        }
        _currentStroke.clear();
      });
      widget.onStrokeUpdated?.call(_strokes.length);
      widget.onStrokesChanged?.call(getNormalizedStrokes());
    }
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    WritingEngine.activeLetter = widget.letter;
    final curStep = activeStepIndex;
    _activeStepIndex = curStep;
    final isLearn = widget.mode == WritingCanvasMode.learn;
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isLearn ? const Color(0xFF3A86FF) : const Color(0xFFFFD166),
          width: 4.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLearn ? const Color(0xFF3A86FF) : const Color(0xFFFFD166))
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              alignment: Alignment.center,
              children: [
                // 0. Letter guide. Drawn from the same glyph outline the stroke paths were
                //    traced on, in the same guide square, so the start/end markers and
                //    paths always sit on the letter. Falls back to the font if no outline.
                if (TamilLetterOutlines.has(widget.letter))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LetterOutlinePainter(letter: widget.letter, isLearn: isLearn),
                      ),
                    ),
                  )
                else if (isLearn)
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 0a. Outer Track Boundary (Soft Educational Blue Border)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 26.0
                                  ..strokeCap = StrokeCap.round
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = const Color(0xFF93C5FD).withValues(alpha: 0.90),
                              ),
                            ),

                            // 0b. Hollow Tracing Channel (Smooth light canal where child traces)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 16.0
                                  ..strokeCap = StrokeCap.round
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = const Color(0xFFF0F7FF),
                              ),
                            ),

                            // 0c. Soft inner letter core (shows authentic glyph shape clearly)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: Text(
                          widget.letter,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Catamaran',
                            fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 1. Progressive Guided Path (Renders ACTIVE STEP ONLY; past steps faint, future steps hidden!)
                if (isLearn && _pulseController != null && _demoController != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseController!, _demoController!]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _LetterPathGuidePainter(
                            letterData: letterData,
                            activeStepIndex: curStep,
                            pulseValue: _pulseController!.value,
                            demoProgress: _demoController!.value,
                            isDemoActive: _isDemoActive,
                            currentStroke: _currentStroke,
                          ),
                        );
                      },
                    ),
                  ),

                // 2. User Drawn Handwriting Strokes
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HandwritingStrokesPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      strokeColor: widget.strokeColor,
                      strokeWidth: widget.strokeWidth,
                      clipBoundary: isLearn
                          ? TamilLetterOutlines.pathFor(widget.letter, WritingEngine.guideRect(_canvasSize))
                          : null,
                    ),
                  ),
                ),

                // 3. Pointer Listener for smooth drawing wrapped in EagerGestureRecognizer
                // to prevent parent SingleChildScrollView from intercepting writing gestures!
                Positioned.fill(
                  child: RawGestureDetector(
                    gestures: {
                      EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                        (EagerGestureRecognizer instance) {},
                      ),
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _onPointerDown(e.localPosition),
                      onPointerMove: (e) => _onPointerMove(e.localPosition),
                      onPointerUp: (e) => _onPointerUp(e.localPosition),
                      onPointerCancel: (_) => _onPointerCancel(),
                    ),
                  ),
                ),

                // 4. Top Action: Demo Play Button: [ ▶ வழிகாட்டல் ▶ ] (Learn Mode)
                if (isLearn && letterData.strokes.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: playCurrentStepDemo,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: _isDemoActive
                                ? const LinearGradient(colors: [Color(0xFFFF9F1C), Color(0xFFFF5400)])
                                : null,
                            color: _isDemoActive ? null : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDemoActive ? const Color(0xFFFF5400) : const Color(0xFF3A86FF),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDemoActive ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                                size: 18,
                                color: _isDemoActive ? Colors.white : const Color(0xFF3A86FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isDemoActive ? 'காட்டுகிறது...' : 'வழிகாட்டல் ▶',
                                style: TextStyle(
                                  fontFamily: 'Catamaran',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _isDemoActive ? Colors.white : const Color(0xFF3A86FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. Feedback when a stroke was traced wrongly (Learn Mode)
                if (isLearn && _hintText != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5964),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5964).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _hintText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Catamaran',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the letter outline as a hollow tracing track (Learn) or a soft watermark (Practice).
class _LetterOutlinePainter extends CustomPainter {
  final String letter;
  final bool isLearn;

  _LetterOutlinePainter({required this.letter, required this.isLearn});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = TamilLetterOutlines.pathFor(letter, WritingEngine.guideRect(size, letter));
    if (path == null) return;

    if (!isLearn) {
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFB703).withValues(alpha: 0.14));
      return;
    }

    // 1. Soft clean groove/canal background
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill,
    );
    // 2. Gentle welcoming inner canal tint
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3A86FF).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // 3. Crisp canal border track
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF93C5FD),
    );
  }

  @override
  bool shouldRepaint(covariant _LetterOutlinePainter oldDelegate) =>
      oldDelegate.letter != letter || oldDelegate.isLearn != isLearn;
}

/// CustomPainter for rendering step-by-step progressive Tamil letter guidance
class _LetterPathGuidePainter extends CustomPainter {
  final TamilWritingLetter letterData;
  final int activeStepIndex;
  final double pulseValue;
  final double demoProgress;
  final bool isDemoActive;
  final List<Offset> currentStroke;

  _LetterPathGuidePainter({
    required this.letterData,
    required this.activeStepIndex,
    required this.pulseValue,
    required this.demoProgress,
    required this.isDemoActive,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (letterData.strokes.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    // 1. Same guide square as the letter outline and the stroke validators
    final double drawSize = WritingEngine.guideRect(size, letterData.letter).width;
    Offset toCanvas(Offset p) => WritingEngine.toCanvas(p, size, letterData.letter);

    final double trackFillWidth = drawSize * 0.055;

    // --- FULL LETTER DEMO MOTION (when demo is triggered) ---
    if (isDemoActive) {
      _drawFullLetterDemoMotion(
        canvas: canvas,
        letterData: letterData,
        toCanvas: toCanvas,
        trackFillWidth: trackFillWidth,
        demoProgress: demoProgress,
        pulseValue: pulseValue,
        size: size,
      );
      return;
    }

    final int safeStep = letterData.strokes.isNotEmpty
        ? activeStepIndex.clamp(0, letterData.strokes.length - 1)
        : 0;

    // --- PHASE 0: Guided Path for all strokes ---
    // Draw future strokes faint dotted path so whole letter shape is visible
    for (int s = safeStep + 1; s < letterData.strokes.length; s++) {
      final futureStroke = letterData.strokes[s];
      if (!futureStroke.isDot && futureStroke.pathPoints.length > 1) {
        final dense = WritingEngine.sampleDensePoints(futureStroke, size);
        _drawDottedPath(canvas, dense, trackFillWidth, alpha: 0.25);
      }
    }

    // Active stroke guidance
    if (safeStep >= 0 && safeStep < letterData.strokes.length) {
      final stroke = letterData.strokes[safeStep];
      if (!stroke.isDot && stroke.pathPoints.length > 1) {
        final checkpoints = WritingBoundaryValidator.getCheckpointPositions(stroke, size);
        final int collectedCount = WritingBoundaryValidator.getCollectedCheckpointsCount(
          userPoints: currentStroke,
          stroke: stroke,
          size: size,
        );

        // 1. Draw Active Segment Dotted Trail
        _drawProgressiveDottedPath(
          canvas: canvas,
          stroke: stroke,
          size: size,
          checkpoints: checkpoints,
          collectedCount: collectedCount,
          trackFillWidth: trackFillWidth,
          isDemoActive: false,
        );

        // 2. Draw Star Checkpoints with Progressive Reveal & Pop Animations
        _drawProgressiveStars(
          canvas: canvas,
          checkpoints: checkpoints,
          collectedCount: collectedCount,
          pulse: pulseValue,
          isDemoActive: false,
        );

        // 3. Draw Red End Marker only when ALL star checkpoints are completed
        final bool showEnd = checkpoints.isEmpty || collectedCount >= checkpoints.length;
        if (showEnd) {
          _drawEndMarker(canvas, toCanvas(stroke.effectiveEndPoint), pulseValue);
        }
      }
    }

    // --- PHASE 1: Draw Start Badge ONLY at current active step start point ---
    if (safeStep >= 0 && safeStep < letterData.strokes.length) {
      final stroke = letterData.strokes[safeStep];
      final startPos = toCanvas(stroke.startPoint);
      _drawStepBadge(
        canvas,
        startPos,
        stroke.strokeNumber,
        pulseValue,
        isCurrent: true,
      );

      // Draw an inviting bouncing direction arrow pointing along the stroke path towards Star 1!
      if (currentStroke.isEmpty && stroke.pathPoints.length > 3) {
        final p0 = toCanvas(stroke.pathPoints[0]);
        final p1 = toCanvas(stroke.pathPoints[3]);
        _drawInitialDirectionArrow(canvas, p0, p1, pulseValue);
      }
    }
  }

  void _drawProgressiveDottedPath({
    required Canvas canvas,
    required LetterStrokeData stroke,
    required Size size,
    required List<Offset> checkpoints,
    required int collectedCount,
    required double trackFillWidth,
    required bool isDemoActive,
  }) {
    if (stroke.pathPoints.length < 2) return;
    final dense = WritingEngine.sampleDensePoints(stroke, size);
    if (dense.length < 2) return;

    if (isDemoActive || checkpoints.isEmpty) {
      _drawDottedPath(canvas, dense, trackFillWidth, alpha: 0.55);
      return;
    }

    final ratios = WritingBoundaryValidator.getCheckpointRatios(stroke);
    final cpIndices = ratios.map((r) => ((dense.length - 1) * r).round().clamp(0, dense.length - 1)).toList();

    int startIdx = 0;
    int endIdx = dense.length - 1;

    if (collectedCount == 0 && cpIndices.isNotEmpty) {
      startIdx = 0;
      endIdx = cpIndices.first;
    } else if (collectedCount > 0 && collectedCount < cpIndices.length) {
      startIdx = cpIndices[collectedCount - 1];
      endIdx = cpIndices[collectedCount];
    } else if (collectedCount >= cpIndices.length) {
      startIdx = cpIndices.isNotEmpty ? cpIndices.last : 0;
      endIdx = dense.length - 1;
    }

    if (endIdx > startIdx) {
      final activeSlice = dense.sublist(startIdx, endIdx + 1);
      _drawDottedPath(canvas, activeSlice, trackFillWidth, alpha: 0.70);
    }
  }

  void _drawDottedPath(Canvas canvas, List<Offset> pts, double trackFillWidth, {double alpha = 0.55}) {
    final dot = Paint()..color = const Color(0xFFFF9F1C).withValues(alpha: alpha);
    final r = math.max(trackFillWidth * 0.14, 2.0);
    final gap = r * 3.8;
    double carry = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final len = (b - a).distance;
      if (len <= 0) continue;
      double d = carry;
      while (d < len) {
        canvas.drawCircle(Offset.lerp(a, b, d / len)!, r, dot);
        d += gap;
      }
      carry = d - len;
    }
  }

  void _drawProgressiveStars({
    required Canvas canvas,
    required List<Offset> checkpoints,
    required int collectedCount,
    required double pulse,
    required bool isDemoActive,
  }) {
    if (checkpoints.isEmpty) return;

    for (int i = 0; i < checkpoints.length; i++) {
      final cp = checkpoints[i];
      final bool isCollected = i < collectedCount;
      final bool isActiveTarget = i == collectedCount;

      if (isDemoActive) {
        _drawStar(
          canvas: canvas,
          center: cp,
          pulse: pulse,
          isCollected: isCollected,
          isActiveTarget: isActiveTarget,
        );
      } else if (isCollected) {
        // 1. Collected Star: Emerald green with celebratory sparkles!
        _drawStar(
          canvas: canvas,
          center: cp,
          pulse: pulse,
          isCollected: true,
          isActiveTarget: false,
        );
      } else if (isActiveTarget) {
        // 2. Active Target Star: Glowing gold, pulsing invitation aura
        _drawStar(
          canvas: canvas,
          center: cp,
          pulse: pulse,
          isCollected: false,
          isActiveTarget: true,
        );
      }
      // 3. Future stars (i > collectedCount) are completely hidden to keep canvas neat!
    }
  }

  void _drawStar({
    required Canvas canvas,
    required Offset center,
    required double pulse,
    required bool isCollected,
    required bool isActiveTarget,
  }) {
    final double outerR = isCollected
        ? 12.0
        : (isActiveTarget ? (9.5 + pulse * 1.8) : 8.5);
    final double innerR = outerR * 0.48;

    // Glowing aura behind the star
    final haloPaint = Paint()
      ..color = (isCollected ? const Color(0xFF10B981) : const Color(0xFFFFB703))
          .withValues(alpha: isCollected ? 0.35 : (0.28 + pulse * 0.22))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR + (isActiveTarget ? 6.5 : 4.0), haloPaint);

    // Build 5-pointed star path
    final starPath = Path();
    const double step = math.pi / 5;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * step) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    // Fill star with golden color (or emerald green if collected)
    final fillPaint = Paint()
      ..color = isCollected ? const Color(0xFF10B981) : const Color(0xFFFFC300)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, fillPaint);

    // Crisp white border
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(starPath, strokePaint);

    // If collected, draw cute sparkling glints around the star!
    if (isCollected) {
      final sparklePaint = Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.fill;
      const sparkleOffsets = [
        Offset(-1.3, -1.3),
        Offset(1.3, -1.3),
        Offset(-1.3, 1.3),
        Offset(1.3, 1.3),
      ];
      for (final off in sparkleOffsets) {
        canvas.drawCircle(center + off * outerR * 0.9, 1.8, sparklePaint);
      }
    }
  }

  void _drawEndMarker(Canvas canvas, Offset center, double pulse) {
    final radius = 8.0 + pulse * 1.2;
    canvas.drawCircle(center, radius + 3, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.22));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawStepBadge(Canvas canvas, Offset center, int stepNumber, double pulse, {required bool isCurrent}) {
    final double baseRadius = 14.5;
    final double radius = isCurrent ? baseRadius + (pulse * 2.2) : baseRadius;

    // Pulsing halo for current active step
    if (isCurrent) {
      final haloPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.35 * (1.0 - pulse))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 8.0 * pulse, haloPaint);
    }

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Badge circle
    final badgePaint = Paint()
      ..color = isCurrent ? const Color(0xFF10B981) : const Color(0xFF3A86FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, badgePaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // Number text
    final textSpan = TextSpan(
      text: '$stepNumber',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'Catamaran',
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawInitialDirectionArrow(Canvas canvas, Offset p0, Offset p1, double pulse) {
    final v = p1 - p0;
    final dist = v.distance;
    if (dist <= 0) return;
    final dir = v / dist;
    final normal = Offset(-dir.dy, dir.dx);

    final bounce = (pulse * 4.5);
    final tip = p0 + dir * (26.0 + bounce);
    final base = tip - dir * 11.0;

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * 6.5, base.dy + normal.dy * 6.5)
      ..lineTo(base.dx - normal.dx * 6.5, base.dy - normal.dy * 6.5)
      ..close();

    final arrowPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arrowPath, borderPaint);
  }

  void _drawSingleStrokeDemoMotion(
    Canvas canvas,
    LetterStrokeData stroke,
    Offset Function(Offset) toCanvas,
    double trackFillWidth,
    double progress,
  ) {
    final canvasPts = stroke.pathPoints.map(toCanvas).toList();
    if (canvasPts.isEmpty) return;

    if (stroke.isDot) {
      final c = toCanvas(stroke.startPoint);
      final r = trackFillWidth * (0.3 + 0.3 * progress);
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFB703)..style = PaintingStyle.fill);
      return;
    }

    if (canvasPts.length < 2) return;

    double totalLen = 0.0;
    final List<double> segmentLens = [];
    for (int i = 0; i < canvasPts.length - 1; i++) {
      final len = (canvasPts[i + 1] - canvasPts[i]).distance;
      segmentLens.add(len);
      totalLen += len;
    }

    if (totalLen <= 0) return;

    final targetDist = progress * totalLen;
    double accumulated = 0.0;
    Offset currentPos = canvasPts.first;

    final trailPaint = Paint()
      ..color = const Color(0xFFFFB703)
      ..strokeWidth = trackFillWidth * 0.72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trailPath = Path()..moveTo(canvasPts.first.dx, canvasPts.first.dy);

    for (int i = 0; i < canvasPts.length - 1; i++) {
      final p0 = canvasPts[i];
      final p1 = canvasPts[i + 1];
      final len = segmentLens[i];

      if (accumulated + len <= targetDist) {
        trailPath.lineTo(p1.dx, p1.dy);
        accumulated += len;
        currentPos = p1;
      } else {
        final remain = targetDist - accumulated;
        final ratio = (remain / (len > 0 ? len : 1.0)).clamp(0.0, 1.0);
        currentPos = Offset(
          p0.dx + (p1.dx - p0.dx) * ratio,
          p0.dy + (p1.dy - p0.dy) * ratio,
        );
        trailPath.lineTo(currentPos.dx, currentPos.dy);
        break;
      }
    }
    canvas.drawPath(trailPath, trailPaint);

    // Glowing Magic Pointer
    final pointerHalo = Paint()
      ..color = const Color(0xFFFF5400).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 16.0, pointerHalo);

    final pointerCore = Paint()
      ..color = const Color(0xFFFFBE0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 9.0, pointerCore);

    final pointerBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(currentPos, 9.0, pointerBorder);

    // Hand icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.touch_app_rounded.codePoint),
        style: TextStyle(
          fontSize: 28,
          fontFamily: Icons.touch_app_rounded.fontFamily,
          package: Icons.touch_app_rounded.fontPackage,
          color: const Color(0xFFFF5400),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(currentPos.dx + 4, currentPos.dy - 28),
    );
  }

  void _drawFullLetterDemoMotion({
    required Canvas canvas,
    required TamilWritingLetter letterData,
    required Offset Function(Offset) toCanvas,
    required double trackFillWidth,
    required double demoProgress,
    required double pulseValue,
    required Size size,
  }) {
    final strokes = letterData.strokes;
    if (strokes.isEmpty) return;

    // 1. Calculate path length of each stroke in canvas pixels
    final List<double> strokeLengths = [];
    double totalLetterLength = 0.0;

    for (final s in strokes) {
      if (s.isDot) {
        final len = trackFillWidth * 1.5;
        strokeLengths.add(len);
        totalLetterLength += len;
      } else {
        final pts = s.pathPoints.map(toCanvas).toList();
        double sLen = 0.0;
        for (int i = 0; i < pts.length - 1; i++) {
          sLen += (pts[i + 1] - pts[i]).distance;
        }
        final finalLen = math.max(sLen, trackFillWidth);
        strokeLengths.add(finalLen);
        totalLetterLength += finalLen;
      }
    }

    if (totalLetterLength <= 0) return;

    // 2. Determine which stroke is currently animating
    final double targetDist = (demoProgress * totalLetterLength).clamp(0.0, totalLetterLength);
    double accumulated = 0.0;
    int activeStrokeIdx = 0;
    double progressInActiveStroke = 0.0;

    for (int i = 0; i < strokes.length; i++) {
      final sLen = strokeLengths[i];
      if (accumulated + sLen <= targetDist && i < strokes.length - 1) {
        accumulated += sLen;
      } else {
        activeStrokeIdx = i;
        final rem = targetDist - accumulated;
        progressInActiveStroke = (rem / (sLen > 0 ? sLen : 1.0)).clamp(0.0, 1.0);
        break;
      }
    }

    // 3. Draw Completed Strokes (strokes < activeStrokeIdx) as solid glowing trails
    for (int i = 0; i < activeStrokeIdx; i++) {
      _drawCompletedStrokeTrail(canvas, strokes[i], toCanvas, trackFillWidth);
    }

    // 4. Draw Future Strokes (strokes > activeStrokeIdx) as faint dotted guide paths
    for (int i = activeStrokeIdx + 1; i < strokes.length; i++) {
      final s = strokes[i];
      if (!s.isDot && s.pathPoints.length > 1) {
        final dense = WritingEngine.sampleDensePoints(s, size);
        _drawDottedPath(canvas, dense, trackFillWidth, alpha: 0.25);
      }
    }

    // 5. Animate Current Stroke
    final activeStroke = strokes[activeStrokeIdx];
    _drawSingleStrokeDemoMotion(
      canvas,
      activeStroke,
      toCanvas,
      trackFillWidth,
      progressInActiveStroke,
    );

    // 6. Draw start badge at the active stroke start point
    final startPos = toCanvas(activeStroke.startPoint);
    _drawStepBadge(
      canvas,
      startPos,
      activeStroke.strokeNumber,
      pulseValue,
      isCurrent: true,
    );

    // 7. Draw red end marker at the final stroke end point if active stroke is the last one
    if (activeStrokeIdx == strokes.length - 1) {
      _drawEndMarker(canvas, toCanvas(activeStroke.effectiveEndPoint), pulseValue);
    }
  }

  void _drawCompletedStrokeTrail(
    Canvas canvas,
    LetterStrokeData stroke,
    Offset Function(Offset) toCanvas,
    double trackFillWidth,
  ) {
    if (stroke.isDot) {
      final c = toCanvas(stroke.startPoint);
      final r = trackFillWidth * 0.6;
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFB703)..style = PaintingStyle.fill);
      return;
    }
    final canvasPts = stroke.pathPoints.map(toCanvas).toList();
    if (canvasPts.length < 2) return;

    final trailPaint = Paint()
      ..color = const Color(0xFFFFB703)
      ..strokeWidth = trackFillWidth * 0.72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trailPath = Path()..moveTo(canvasPts.first.dx, canvasPts.first.dy);
    for (int i = 1; i < canvasPts.length; i++) {
      trailPath.lineTo(canvasPts[i].dx, canvasPts[i].dy);
    }
    canvas.drawPath(trailPath, trailPaint);
  }

  @override
  bool shouldRepaint(covariant _LetterPathGuidePainter oldDelegate) => true;
}

/// Vibrant Rainbow Stroke Painter with optional letter boundary clipping mask
class _HandwritingStrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;
  final Path? clipBoundary;

  _HandwritingStrokesPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
    this.clipBoundary,
  });

  // Kid-friendly cheerful rainbow palette
  static const List<Color> _rainbowColors = [
    Color(0xFFFF1361), // Vibrant Neon Pink
    Color(0xFFFF5400), // Electric Orange
    Color(0xFFFFD166), // Sunshine Yellow
    Color(0xFF06D6A0), // Emerald Green
    Color(0xFF00C49F), // Fresh Turquoise
    Color(0xFF118AB2), // Bright Ocean Blue
    Color(0xFF7209B7), // Royal Purple
    Color(0xFFF72585), // Magenta Rose
  ];

  static Color _getRainbowColor(double progress) {
    final double t = progress.clamp(0.0, 1.0);
    final double scaled = t * (_rainbowColors.length - 1);
    final int idx = scaled.floor();
    final double remainder = scaled - idx;
    if (idx >= _rainbowColors.length - 1) return _rainbowColors.last;
    return Color.lerp(_rainbowColors[idx], _rainbowColors[idx + 1], remainder)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double guideWidth = WritingEngine.guideRect(size).width;
    // Dynamic brush thickness that fits the canal cleanly without blooming into adjacent strokes
    final double effectiveWidth = math.max(strokeWidth * 1.5, guideWidth * 0.095);

    canvas.save();
    if (clipBoundary != null) {
      // Clean mask: strokes cannot spill outside the letter canal!
      canvas.clipPath(clipBoundary!);
    }

    // Paint completed strokes
    for (int s = 0; s < strokes.length; s++) {
      _drawRainbowStroke(canvas, strokes[s], effectiveWidth);
    }

    // Paint active stroke
    if (currentStroke.isNotEmpty) {
      _drawRainbowStroke(canvas, currentStroke, effectiveWidth);
    }

    canvas.restore();

    // Redraw crisp canal border on top of the rainbow fill for a clean sticker/coloring-book finish!
    if (clipBoundary != null) {
      canvas.drawPath(
        clipBoundary!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF93C5FD),
      );
    }
  }

  void _drawRainbowStroke(Canvas canvas, List<Offset> stroke, double width) {
    if (stroke.isEmpty) return;

    if (stroke.length == 1) {
      final color = _getRainbowColor(0.2);
      canvas.drawCircle(
        stroke.first,
        width * 0.75,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    final int n = stroke.length;
    for (int i = 0; i < n - 1; i++) {
      final double progress = (i / (n - 1));
      final color = _getRainbowColor(progress);
      final p0 = stroke[i];
      final p1 = stroke[i + 1];

      // 1. Soft glowing aura under the stroke
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = width + 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );

      // 2. Core flood-fill rainbow line that saturates the whole canal
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingStrokesPainter oldDelegate) => true;
}

/// Standalone preview widget that renders previously saved strokes
class SavedHandwritingPreview extends StatelessWidget {
  final List<List<WritingPoint>> strokes;
  final String? ghostLetter;
  final Color strokeColor;
  final double strokeWidth;
  final Color backgroundColor;

  const SavedHandwritingPreview({
    super.key,
    required this.strokes,
    this.ghostLetter,
    this.strokeColor = const Color(0xFF3A86FF),
    this.strokeWidth = 4.0,
    this.backgroundColor = const Color(0xFFF8F9FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            if (ghostLetter != null && ghostLetter!.isNotEmpty)
              Positioned.fill(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        ghostLetter!,
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.12),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SavedPreviewPainter(
                  strokes: strokes,
                  strokeColor: strokeColor,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPreviewPainter extends CustomPainter {
  final List<List<WritingPoint>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SavedPreviewPainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.x * size.width, stroke.first.y * size.height),
          strokeWidth / 2,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].x * size.width, stroke[i].y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SavedPreviewPainter oldDelegate) => true;
}
