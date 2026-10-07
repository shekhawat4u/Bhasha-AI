import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_pill.dart';
import 'language_sheet.dart';
import 'settings_sheet.dart';
import 'listening_screen.dart';
import 'document_screen.dart';
import 'video_screen.dart';
import 'audio_screen.dart';
import 'intelligence_screen.dart';
import 'stratcomn_screen.dart';
import 'authenticator_screen.dart';
import 'threat_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitTranslation(AppState appState) {
    if (_textController.text.trim().isNotEmpty) {
      final text = _textController.text.trim();
      appState.translateInputText(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showAttachmentOptions(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operational Suites & Tactical Tools',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(CupertinoIcons.waveform_circle_fill, color: AppTheme.primary, size: 28),
                    title: const Text('Audio Intelligence & Diarization', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Spectral noise suppression, speaker diarization & voiceprints', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const IntelligenceScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.antenna_radiowaves_left_right, color: Colors.blueAccent, size: 28),
                    title: const Text('Tactical Broadcast & RF Studio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Timed multi-speaker scripts, voice cloning & RF simulation', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StratComnScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppTheme.activeGreen, size: 28),
                    title: const Text('Voice Authenticator & Forensics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Spectral phase, vocoder anomaly & deepfake forensic detector', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthenticatorScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 28),
                    title: const Text('Threat Keyword Interceptor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Real-time danger keywords, munitions & coordinate alarms', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ThreatScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.lock_shield_fill, color: Colors.amber, size: 28),
                    title: const Text('Encrypted Evidence Vault', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('AES-256 military storage, biometric registry & SHA-256 hash', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VaultScreen()),
                      );
                    },
                  ),
                  const Divider(color: AppTheme.border),
                  ListTile(
                    leading: const Icon(CupertinoIcons.mic_circle_fill, color: Colors.orangeAccent, size: 28),
                    title: const Text('Standard Audio Translation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Transcribe & translate .mp3, .wav, .m4a operational comms', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await appState.pickAndTranslateAudio();
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AudioScreen()),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primary, size: 28),
                    title: const Text('PDF / Document Translation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Translate multi-page manuals and tactical briefs', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await appState.pickAndTranslateDocument();
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DocumentScreen()),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.film_fill, color: Colors.purpleAccent, size: 28),
                    title: const Text('Video / Media Subtitling', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Extract timestamped synchronized speech transcripts', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VideoScreen()),
                      );
                      appState.pickAndTranslateVideo();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasText = _textController.text.trim().isNotEmpty;
    final hasResult = appState.currentResult.sourceText.isNotEmpty || appState.isTranslating;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
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

              // Language Selector Pill: [ English ▾ ] <-> [ Hindi ▾ ]
              Center(
                child: LanguagePill(
                  sourceLang: appState.sourceLang,
                  targetLang: appState.targetLang,
                  sourceCustomLabel: (appState.currentResult.detectedLang.isNotEmpty && appState.currentResult.detectedLang != 'Auto')
                      ? appState.currentResult.detectedLang
                      : null,
                  detectedBadge: (appState.currentResult.detectedLang.isNotEmpty && appState.currentResult.detectedLang != 'Auto')
                      ? 'DETECTED'
                      : null,
                  onSourceTap: () => LanguageSheet.show(context, isSource: true),
                  onTargetTap: () => LanguageSheet.show(context, isSource: false),
                  onSwapTap: () => appState.swapLanguages(),
                ),
              ),

              const SizedBox(height: 12),

              // Tactical Suite Quick Switcher Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.waveform_path_ecg,
                      label: 'Audio Intel',
                      color: AppTheme.primary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const IntelligenceScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.antenna_radiowaves_left_right,
                      label: 'Broadcast RF',
                      color: Colors.blueAccent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StratComnScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.shield_fill,
                      label: 'Voice Auth',
                      color: AppTheme.activeGreen,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthenticatorScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      label: 'Threat Scanner',
                      color: Colors.redAccent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ThreatScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.lock_shield_fill,
                      label: 'Secure Vault',
                      color: Colors.amber,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VaultScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.film,
                      label: 'Video Sub',
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VideoScreen()),
                        );
                        appState.pickAndTranslateVideo();
                      },
                    ),
                    const SizedBox(width: 8),
                    _TacticalSuiteChip(
                      icon: CupertinoIcons.doc_text,
                      label: 'Docs',
                      color: Colors.teal,
                      onTap: () async {
                        await appState.pickAndTranslateDocument();
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DocumentScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Main Translation Area
              Expanded(
                child: !hasResult
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.textformat_alt,
                                size: 28,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Translate text or speech',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Type below in any language or tap mic to speak',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. User Input / Source Text Box
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
                                      Text(
                                        () {
                                          if (RegExp(r'[\u4e00-\u9fff]').hasMatch(appState.currentResult.sourceText)) {
                                            return 'CHINESE (INPUT)';
                                          }
                                          if (appState.currentResult.detectedLang.isNotEmpty) {
                                            return '${appState.currentResult.detectedLang.toUpperCase()} (INPUT)';
                                          }
                                          return '${appState.sourceLang.name.toUpperCase()} (INPUT)';
                                        }(),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: appState.currentResult.sourceText));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Original text copied'),
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
                                  const SizedBox(height: 8),
                                  Text(
                                    appState.currentResult.sourceText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 2. Translated Output Text Box
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
                                      Text(
                                        '${appState.targetLang.name.toUpperCase()} (TRANSLATED)',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (appState.isTranslating) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Translating...',
                                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      appState.currentResult.translatedText,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Action icons: Speaker (TTS), Copy, Share
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            if (appState.currentResult.translatedText.isNotEmpty) {
                                              appState.speakText(
                                                appState.currentResult.translatedText,
                                                langCode: appState.targetLang.code,
                                              );
                                            }
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
                                        const SizedBox(width: 12),
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
                          ],
                        ),
                      ),
              ),

              // Bottom Bar: Text Input Pill + Enhanced Send Button / Mic Button
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: Row(
                  children: [
                    // Text Input Pill
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: hasText ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _showAttachmentOptions(context, appState),
                              icon: const Icon(CupertinoIcons.paperclip, size: 18, color: AppTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                onSubmitted: (_) => _submitTranslation(appState),
                                textInputAction: TextInputAction.send,
                                decoration: const InputDecoration(
                                  hintText: 'Type text in any language...',
                                  hintStyle: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (hasText)
                              IconButton(
                                onPressed: () {
                                  _textController.clear();
                                },
                                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16, color: AppTheme.textMuted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Better Send Button (Active Primary button when text entered, Mic button when idle)
                    if (hasText)
                      GestureDetector(
                        onTap: () => _submitTranslation(appState),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_up,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          appState.startListening();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ListeningScreen()),
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.mic_fill,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
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

class _TacticalSuiteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TacticalSuiteChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
