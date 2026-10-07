import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/gpu_api_service.dart';

class AuthenticatorScreen extends StatefulWidget {
  const AuthenticatorScreen({super.key});

  @override
  State<AuthenticatorScreen> createState() => _AuthenticatorScreenState();
}

class _AuthenticatorScreenState extends State<AuthenticatorScreen> {
  final GpuApiService _apiService = GpuApiService();

  bool _isAnalyzing = false;
  String? _fileName;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.path != null) {
        final path = result.path!;
        setState(() {
          _fileName = result.name;
        });
        _analyzeDeepfake(path);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _analyzeDeepfake(String path) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      final res = await _apiService.detectDeepfake(filePath: path);

      setState(() {
        _analysisResult = res;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReal = _analysisResult?['classification'] == 'REAL';
    final confidence = (_analysisResult?['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final metrics = (_analysisResult?['forensic_metrics'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Voice Authenticator & Forensics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            Text(
              'Spectral Phase • Micro-Jitter • Deepfake Detector',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppTheme.primary),
            tooltip: 'Select Intercept Audio',
            onPressed: _pickAudioFile,
          ),
        ],
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CupertinoActivityIndicator(radius: 20, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Running Deepfake Forensic Analysis...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyzing spectral phase continuity, vocoder harmonics & pitch micro-jitter',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _analysisResult == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(CupertinoIcons.shield_fill, size: 40, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Voice Authenticator & Anti-Spoofing',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Identify AI-synthesized clones, neural vocoder artifacts, and deepfake transmissions in enemy radio chatter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: _pickAudioFile,
                            icon: const Icon(CupertinoIcons.waveform_circle, size: 18),
                            label: const Text('Probe Intercept Audio File', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Result Banner (REAL vs FAKE)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isReal ? AppTheme.activeGreen.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isReal ? AppTheme.activeGreen : Colors.redAccent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isReal ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill,
                                size: 48,
                                color: isReal ? AppTheme.activeGreen : Colors.redAccent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isReal ? 'AUTHENTIC HUMAN VOICE' : 'SYNTHETIC DEEPFAKE / CLONE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isReal ? AppTheme.activeGreen : Colors.redAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _analysisResult?['verdict'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isReal ? AppTheme.activeGreen.withValues(alpha: 0.8) : Colors.redAccent.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Forensic Confidence: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    Text(
                                      '${confidence.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isReal ? AppTheme.activeGreen : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Forensic Metrics Breakdown
                        const Text(
                          'FORENSIC DSP & BIOMETRIC BREAKDOWN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              _ForensicBar(
                                title: 'Harmonic Phase Continuity',
                                score: (metrics['phase_continuity_score'] as num?)?.toDouble() ?? 0.0,
                                isPositiveMetric: true,
                              ),
                              const SizedBox(height: 14),
                              _ForensicBar(
                                title: 'Vocal Micro-Jitter Naturalness',
                                score: (metrics['pitch_jitter_naturalness'] as num?)?.toDouble() ?? 0.0,
                                isPositiveMetric: true,
                              ),
                              const SizedBox(height: 14),
                              _ForensicBar(
                                title: 'High-Frequency Vocoder Anomaly',
                                score: (metrics['high_freq_vocoder_anomaly'] as num?)?.toDouble() ?? 0.0,
                                isPositiveMetric: false,
                              ),
                              const SizedBox(height: 14),
                              _ForensicBar(
                                title: 'Biometric Vocal-Tract Integrity',
                                score: (metrics['biometric_integrity'] as num?)?.toDouble() ?? 0.0,
                                isPositiveMetric: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tactical Assessment
                        const Text(
                          'TACTICAL INTELLIGENCE ASSESSMENT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.doc_text_search, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Source: ${_fileName ?? "Audio Stream"}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _analysisResult?['tactical_assessment'] ?? 'Analysis complete.',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Re-probe Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _pickAudioFile,
                            icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
                            label: const Text('Probe Another Audio Stream'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _ForensicBar extends StatelessWidget {
  final String title;
  final double score;
  final bool isPositiveMetric;

  const _ForensicBar({
    required this.title,
    required this.score,
    required this.isPositiveMetric,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0);
    final isGood = isPositiveMetric ? clamped >= 0.7 : clamped <= 0.3;
    final color = isGood ? AppTheme.activeGreen : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('${(clamped * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
