import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_pill.dart';
import '../widgets/audio_visualizer.dart';
import 'language_sheet.dart';
import 'settings_sheet.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

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
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer!.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
        }
      });

      _audioPlayer!.onDurationChanged.listen((dur) {
        if (mounted) {
          setState(() {
            _totalDuration = dur;
          });
        }
      });
    } catch (e) {
      debugPrint('AudioPlayer initialization notice: $e');
    }
  }

  @override
  void dispose() {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _togglePlay(String? filePath) async {
    if (_isPlaying) {
      try {
        await _audioPlayer?.pause();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
        try {
          _audioPlayer ??= AudioPlayer();
          await _audioPlayer!.play(DeviceFileSource(filePath));
        } catch (e) {
          debugPrint('Audio playback notice: $e');
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final audio = appState.attachedAudio;
    final detectedLang = audio?.detectedLang.isNotEmpty == true
        ? audio!.detectedLang
        : (appState.isIndianLanguagesMode ? appState.sourceLang.name : 'Auto');

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
                      ],
                    ),
                    IconButton(
                      onPressed: () => SettingsSheet.show(context),
                      icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: AppTheme.textSecondary),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Language Selector (Exact same design as Home Screen)
              Center(
                child: LanguagePill(
                  sourceLang: appState.sourceLang,
                  targetLang: appState.targetLang,
                  sourceCustomLabel: detectedLang,
                  detectedBadge: 'AUTO',
                  allowSourceSelection: false,
                  isOneWay: true,
                  onSourceTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio source language is auto-detected'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onTargetTap: () => LanguageSheet.show(context, isSource: false),
                ),
              ),

              const SizedBox(height: 16),

              // Attached Audio File Card with Player Bar
              if (audio != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.waveform_circle_fill, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audio.fileName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _totalDuration.inSeconds > 0
                                      ? '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)} • ${audio.latencyMs}ms'
                                      : '${audio.duration} • Latency: ${audio.latencyMs}ms',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _togglePlay(audio.filePath),
                            icon: Icon(
                              _isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                              size: 30,
                              color: AppTheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              try {
                                _audioPlayer?.stop();
                              } catch (_) {}
                              appState.removeAttachedAudio();
                              Navigator.pop(context);
                            },
                            icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: AppTheme.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          ),
                        ],
                      ),
                      if (_isPlaying) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: AudioVisualizer(
                            maxHeight: 24,
                            barLevels: appState.visualizerBars,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Transcription and Translation Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (appState.isTranslating) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Transcribing audio on GPU & translating...',
                                  style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (audio != null) ...[
                        // 0. Actionable Tactical Intelligence (Gist Card)
                        // 0. Actionable Tactical Intelligence (Gist Card) - On-Demand Qwen 2.5 7B
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
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                  if (audio.tacticalGist.isNotEmpty && !appState.isGeneratingGist) ...[
                                    InkWell(
                                      onTap: () => appState.fetchTacticalGistForAudio(),
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(CupertinoIcons.arrow_clockwise, size: 14, color: AppTheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: audio.tacticalGist));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tactical gist copied'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
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
                              else if (audio.tacticalGist.isNotEmpty)
                                Text(
                                  audio.tacticalGist,
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
                                  onTap: () => appState.fetchTacticalGistForAudio(),
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
                        const SizedBox(height: 16),

                        // 1. Source Audio Transcription Card (Verbatim Speech)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${detectedLang.toUpperCase()} (VERBATIM TRANSCRIPTION)',
                                      style: const TextStyle(
                                        fontSize: 9.5,
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
                                      Clipboard.setData(ClipboardData(text: audio.sourceText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Transcription copied'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                audio.sourceText.isNotEmpty ? audio.sourceText : 'No speech detected in audio file.',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 2. Target Audio Translation Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
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
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${appState.targetLang.name.toUpperCase()} (TRANSLATION)',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                audio.translatedText.isNotEmpty ? audio.translatedText : 'Processing translation...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  height: 1.35,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Actions: Speak & Copy (Clean 2 buttons)
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (audio.translatedText.isNotEmpty) {
                                        appState.speakText(
                                          audio.translatedText,
                                          langCode: appState.targetLang.code,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      (appState.isPlayingTts && appState.currentSpeakingText == audio.translatedText)
                                          ? CupertinoIcons.speaker_3_fill
                                          : CupertinoIcons.speaker_2,
                                      size: 18,
                                      color: (appState.isPlayingTts && appState.currentSpeakingText == audio.translatedText)
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: audio.translatedText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Copied translation to clipboard'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(CupertinoIcons.doc_on_doc, size: 18, color: AppTheme.textMuted),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions: [ Translate into Target Language ]
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (audio != null) {
                        appState.retranslateAttachedAudio();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkPill,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Translate into ${appState.targetLang.name}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
