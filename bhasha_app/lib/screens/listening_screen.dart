import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_pill.dart';
import '../widgets/audio_visualizer.dart';
import 'language_sheet.dart';
import 'settings_sheet.dart';

class ListeningScreen extends StatelessWidget {
  const ListeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final minutes = (appState.listeningSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (appState.listeningSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

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
                          decoration: const BoxDecoration(
                            color: AppTheme.activeGreen,
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

              // Language Selector with dynamic DETECTED language display
              Center(
                child: LanguagePill(
                  sourceLang: appState.sourceLang,
                  targetLang: appState.targetLang,
                  sourceCustomLabel: (appState.currentResult.detectedLang.isNotEmpty && appState.currentResult.detectedLang != 'Auto')
                      ? appState.currentResult.detectedLang
                      : (appState.detectLanguage ? 'Auto Detect' : appState.sourceLang.name),
                  detectedBadge: (appState.currentResult.detectedLang.isNotEmpty && appState.currentResult.detectedLang != 'Auto')
                      ? 'DETECTED'
                      : 'LIVE STREAM',
                  onSourceTap: () => LanguageSheet.show(context, isSource: true),
                  onTargetTap: () => LanguageSheet.show(context, isSource: false),
                  onSwapTap: () => appState.swapLanguages(),
                ),
              ),

              const SizedBox(height: 28),

              // Transcribed original text & Large Translated Text (Continuous unified display)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Original Spoken Transcript
                      Text(
                        (appState.currentResult.sourceText.isNotEmpty && appState.currentResult.sourceText != 'Listening...')
                            ? appState.currentResult.sourceText
                            : 'Listening...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: (appState.currentResult.sourceText.isNotEmpty && appState.currentResult.sourceText != 'Listening...')
                              ? AppTheme.textMuted
                              : AppTheme.textSecondary.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Main Large Translated Output
                      Text(
                        (appState.currentResult.translatedText.isNotEmpty && appState.currentResult.translatedText != 'Translating in real-time...')
                            ? appState.currentResult.translatedText
                            : 'Translating in real-time...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: (appState.currentResult.translatedText.isNotEmpty && appState.currentResult.translatedText != 'Translating in real-time...')
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary.withValues(alpha: 0.6),
                          height: 1.35,
                          letterSpacing: -0.3,
                        ),
                      ),

                      if (appState.currentResult.translatedText.isNotEmpty &&
                          appState.currentResult.translatedText != 'Translating in real-time...') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                appState.speakText(
                                  appState.currentResult.translatedText,
                                  langCode: appState.targetLang.code,
                                );
                              },
                              icon: Icon(
                                (appState.isPlayingTts && appState.currentSpeakingText == appState.currentResult.translatedText)
                                    ? CupertinoIcons.speaker_3_fill
                                    : CupertinoIcons.speaker_2,
                                size: 18,
                                color: (appState.isPlayingTts && appState.currentSpeakingText == appState.currentResult.translatedText)
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: appState.currentResult.translatedText));
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
                    ],
                  ),
                ),
              ),

              // Bottom Audio Telemetry & Visualizer
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Clean live recording indicator and timer
                    Text(
                      'LIVE RECORDING  •  $timeStr',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Waveform + Stop Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Audio visualizer bars
                        AudioVisualizer(
                          barLevels: appState.visualizerBars,
                          maxHeight: 28,
                        ),

                        // Red Stop Button (Circle with white square)
                        GestureDetector(
                          onTap: () {
                            appState.stopListening();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
