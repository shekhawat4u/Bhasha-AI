import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/video_subtitle.dart';
import '../widgets/language_pill.dart';
import 'language_sheet.dart';
import 'settings_sheet.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  String? _currentLoadedPath;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 77);
  Timer? _sampleTimer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing || (_videoController?.value.isPlaying ?? false);
          });
        }
      });
      _audioPlayer!.onPositionChanged.listen((pos) {
        if (mounted && (!_isInitialized || _videoController == null)) {
          setState(() {
            _position = pos;
          });
        }
      });
      _audioPlayer!.onDurationChanged.listen((dur) {
        if (mounted && dur > Duration.zero) {
          setState(() {
            _duration = dur;
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sampleTimer?.cancel();
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    try {
      _videoController?.removeListener(_videoListener);
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
    _isInitialized = false;
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final val = _videoController!.value;
    setState(() {
      _isPlaying = val.isPlaying || (_audioPlayer?.state == PlayerState.playing);
      _position = val.position;
      if (val.duration > Duration.zero) {
        _duration = val.duration;
      }
    });
  }

  Future<void> _setupController(String? streamUrl, String? filePath) async {
    final target = (filePath != null && filePath.isNotEmpty) ? filePath : streamUrl;
    if (target == null || target.isEmpty) return;
    if (_currentLoadedPath == target && _isInitialized && _videoController != null) return;

    _sampleTimer?.cancel();
    _disposeVideoController();
    _currentLoadedPath = target;

    bool videoInitialized = false;

    // 1. Try local file FIRST if it exists and is an MP4 or valid video
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final controller = VideoPlayerController.file(file);
          _videoController = controller;
          await controller.initialize();
          controller.addListener(_videoListener);
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _duration = controller.value.duration;
              _position = controller.value.position;
              _isPlaying = controller.value.isPlaying;
            });
          }
          videoInitialized = true;
        }
      } catch (e) {
        debugPrint('Local file video player initialization error: $e');
        _disposeVideoController();
      }
    }

    // 2. If local file controller failed (or not an MP4), try streamUrl (network H.264 MP4 with Range support)
    if (!videoInitialized && streamUrl != null && streamUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(streamUrl);
        final controller = VideoPlayerController.networkUrl(uri);
        _videoController = controller;
        await controller.initialize();
        controller.addListener(_videoListener);
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _duration = controller.value.duration;
            _position = controller.value.position;
            _isPlaying = controller.value.isPlaying;
          });
        }
        videoInitialized = true;
      } catch (e) {
        debugPrint('Network video player initialization error: $e');
        _disposeVideoController();
      }
    }

    // 3. Setup AudioPlayer as fallback only if video controller couldn't initialize
    if (!videoInitialized) {
      try {
        _audioPlayer ??= AudioPlayer();
        if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
          await _audioPlayer!.setSource(DeviceFileSource(filePath));
        } else if (streamUrl != null && streamUrl.isNotEmpty) {
          await _audioPlayer!.setSource(UrlSource(streamUrl));
        }
      } catch (e) {
        debugPrint('Audio source notice: $e');
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      try {
        await _videoController?.pause();
      } catch (_) {}
      try {
        await _audioPlayer?.pause();
      } catch (_) {}
      _sampleTimer?.cancel();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (_videoController != null && _isInitialized) {
        if (_position >= _duration && _duration > Duration.zero) {
          await _videoController!.seekTo(Duration.zero);
        }
        await _videoController!.play();
        if (mounted) setState(() => _isPlaying = true);
      } else if (_currentLoadedPath != null && _currentLoadedPath!.isNotEmpty) {
        try {
          _audioPlayer ??= AudioPlayer();
          if (_position >= _duration && _duration > Duration.zero) {
            await _audioPlayer!.seek(Duration.zero);
          }
          if (_currentLoadedPath!.startsWith('http')) {
            await _audioPlayer!.play(UrlSource(_currentLoadedPath!));
          } else if (File(_currentLoadedPath!).existsSync()) {
            await _audioPlayer!.play(DeviceFileSource(_currentLoadedPath!));
          }
        } catch (e) {
          debugPrint('Audio playback error: $e');
        }
        if (mounted) setState(() => _isPlaying = true);
      } else {
        // Simulated playback for sample / preview video
        if (_position >= _duration) {
          _position = Duration.zero;
        }
        _sampleTimer?.cancel();
        _sampleTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            final nextMs = _position.inMilliseconds + 250;
            if (nextMs >= _duration.inMilliseconds) {
              _position = _duration;
              _isPlaying = false;
              timer.cancel();
            } else {
              _position = Duration(milliseconds: nextMs);
            }
          });
        });
        if (mounted) setState(() => _isPlaying = true);
      }
    }
  }

  Future<void> _stopVideo() async {
    try {
      await _videoController?.pause();
      await _videoController?.seekTo(Duration.zero);
    } catch (_) {}
    try {
      await _audioPlayer?.pause();
      await _audioPlayer?.seek(Duration.zero);
    } catch (_) {}
    _sampleTimer?.cancel();

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    }
  }

  void _seekTo(Duration target) {
    try {
      _videoController?.seekTo(target);
    } catch (_) {}
    try {
      _audioPlayer?.seek(target);
    } catch (_) {}
    setState(() {
      _position = target;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final vid = appState.attachedVideo;
    final detectedLang = vid?.detectedLang.isNotEmpty == true
        ? vid!.detectedLang
        : (appState.isIndianLanguagesMode ? appState.sourceLang.name : 'Auto');

    // Automatically initialize player when streamUrl or filePath is available
    final currentTarget = (vid?.streamUrl != null && vid!.streamUrl!.isNotEmpty)
        ? vid.streamUrl
        : vid?.filePath;
    if (currentTarget != null && currentTarget.isNotEmpty && currentTarget != _currentLoadedPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupController(vid?.streamUrl, vid?.filePath);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: appState.isGpuConnected ? AppTheme.activeGreen : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bhasha AI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIDEO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => SettingsSheet.show(context),
                          icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: AppTheme.textSecondary),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Language Selector: Source is locked to detected/auto, Target is user-selectable (defaults to EN)
              Center(
                child: LanguagePill(
                  sourceLang: appState.sourceLang,
                  targetLang: appState.targetLang,
                  sourceCustomLabel: detectedLang,
                  isOneWay: true,
                  detectedBadge: 'AUTO',
                  allowSourceSelection: false,
                  onSourceTap: () {},
                  onTargetTap: () => LanguageSheet.show(context, isSource: false),
                  onSwapTap: () {},
                ),
              ),

              const SizedBox(height: 14),

              // Video Player Viewport Box
              _buildVideoPlayerViewport(vid),

              const SizedBox(height: 14),

              // Content Area: Full Paragraph Transcription & Full Paragraph Translation
              Expanded(
                child: appState.isTranslating
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Extracting audio & translating video...',
                              style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: ${appState.targetLang.name}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : vid == null
                        ? _buildEmptyVideoState(context, appState)
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Video Title & Metadata Tag
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceAlt.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(CupertinoIcons.film, size: 16, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vid.videoTitle,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${vid.duration} • Latency: ${vid.latencyMs}ms',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 0. Actionable Tactical Gist Card - On-Demand Qwen 2.5 7B
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primary.withValues(alpha: 0.08),
                                        AppTheme.surface,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(CupertinoIcons.shield_lefthalf_fill, color: Colors.white, size: 11),
                                                SizedBox(width: 4),
                                                Text(
                                                  'ACTIONABLE TACTICAL GIST',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          if (vid.tacticalGist.isNotEmpty && !appState.isGeneratingGist) ...[
                                            InkWell(
                                              onTap: () => appState.fetchTacticalGistForVideo(),
                                              borderRadius: BorderRadius.circular(8),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(CupertinoIcons.arrow_clockwise, size: 14, color: AppTheme.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: vid.tacticalGist));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Tactical gist copied!'), duration: Duration(seconds: 1)),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppTheme.primary),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (appState.isGeneratingGist)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Generating Gist...',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (vid.tacticalGist.isNotEmpty)
                                        Text(
                                          vid.tacticalGist,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                            height: 1.45,
                                            letterSpacing: -0.2,
                                          ),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => appState.fetchTacticalGistForVideo(),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(CupertinoIcons.sparkles, size: 16, color: AppTheme.primary),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Show Gist',
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 1. Original Speech Transcription Card (Whole Paragraph)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceAlt,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${detectedLang.toUpperCase()} (ORIGINAL TRANSCRIPTION)',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textSecondary,
                                                letterSpacing: 0.6,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: vid.sourceText));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Transcription copied to clipboard!'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppTheme.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        vid.sourceText.isNotEmpty
                                            ? vid.sourceText
                                            : (vid.subtitles.isNotEmpty
                                                ? vid.subtitles.map((s) => s.originalText).join(' ')
                                                : 'No speech detected in video audio track.'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 2. Translated Text Card (Whole Paragraph)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${appState.targetLang.name.toUpperCase()} (TRANSLATION)',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primary,
                                                letterSpacing: 0.6,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  final textToSpeak = vid.translatedText.isNotEmpty
                                                      ? vid.translatedText
                                                      : vid.subtitles.map((s) => s.translatedText).join(' ');
                                                  if (textToSpeak.isNotEmpty) {
                                                    appState.speakText(
                                                      textToSpeak,
                                                      langCode: appState.targetLang.code,
                                                    );
                                                  }
                                                },
                                                icon: Icon(
                                                  (appState.isPlayingTts && (appState.currentSpeakingText == vid.translatedText || appState.currentSpeakingText == vid.subtitles.map((s) => s.translatedText).join(' ')))
                                                      ? CupertinoIcons.speaker_3_fill
                                                      : CupertinoIcons.speaker_2,
                                                  size: 16,
                                                  color: (appState.isPlayingTts && (appState.currentSpeakingText == vid.translatedText || appState.currentSpeakingText == vid.subtitles.map((s) => s.translatedText).join(' ')))
                                                      ? AppTheme.primary
                                                      : AppTheme.textMuted,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: vid.translatedText));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Translation copied to clipboard!'),
                                                      duration: Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(CupertinoIcons.doc_on_doc, size: 16, color: AppTheme.textMuted),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        vid.translatedText.isNotEmpty
                                            ? vid.translatedText
                                            : (vid.subtitles.isNotEmpty
                                                ? vid.subtitles.map((s) => s.translatedText).join(' ')
                                                : '(Translating...)'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
              ),

              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => appState.pickAndTranslateVideo(),
                        icon: const Icon(CupertinoIcons.video_camera, size: 18),
                        label: Text(
                          vid == null ? 'Upload Video' : 'Upload New Video',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (vid != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _sampleTimer?.cancel();
                            _disposeVideoController();
                            setState(() {
                              _isPlaying = false;
                              _position = Duration.zero;
                              _duration = const Duration(seconds: 77);
                            });
                            appState.loadSampleVideo();
                          },
                          icon: const Icon(CupertinoIcons.sparkles, size: 18, color: AppTheme.primary),
                          tooltip: 'Load Sample Video',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerViewport(VideoMediaTranslation? vid) {
    final hasRealVideo = _isInitialized && _videoController != null;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: 195,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Surface (Real texture or animated simulated canvas)
          if (hasRealVideo)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio > 0
                    ? _videoController!.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _isPlaying ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    _isPlaying ? const Color(0xFF0F172A) : const Color(0xFF020617),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? CupertinoIcons.play_circle_fill : (vid != null ? CupertinoIcons.film : CupertinoIcons.video_camera),
                      color: _isPlaying ? AppTheme.primary.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vid?.videoTitle ?? 'No Video Selected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vid != null && _isPlaying)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Playing audio & video stream...',
                          style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 2. Center Tap Play/Pause Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _togglePlay,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isPlaying ? 0.0 : 0.9,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Controls Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Play / Pause Button
                  InkWell(
                    onTap: _togglePlay,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                  // Stop Button
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _stopVideo,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        CupertinoIcons.stop_fill,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Interactive Seek Slider / Progress Bar
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: AppTheme.primary,
                        overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          if (_duration > Duration.zero) {
                            final target = Duration(milliseconds: (val * _duration.inMilliseconds).toInt());
                            _seekTo(target);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Duration text
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVideoState(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.video_camera, size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload a Video to Translate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Extracts audio directly and generates full transcription\nand neural translation into English',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => appState.loadSampleVideo(),
            icon: const Icon(CupertinoIcons.sparkles, size: 16),
            label: const Text('Try Sample Video'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
