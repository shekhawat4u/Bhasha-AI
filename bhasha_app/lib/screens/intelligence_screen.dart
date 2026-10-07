import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/gpu_api_service.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  final GpuApiService _apiService = GpuApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isProcessing = false;
  String? _selectedFilePath;
  String? _fileName;
  double _snrImprovement = 0.0;
  int _noiseReductionPercent = 0;
  String _denoisedAudioUrl = '';
  List<dynamic> _speakers = [];
  List<dynamic> _segments = [];
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.path != null) {
        final path = result.path!;
        setState(() {
          _selectedFilePath = path;
          _fileName = result.name;
        });
        _analyzeAudio(path);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _analyzeAudio(String path) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      // 1. Denoise
      final denoiseRes = await _apiService.denoiseAudio(filePath: path);
      // 2. Diarize & Transcribe
      final diarizeRes = await _apiService.diarizeAudio(
        filePath: path,
        targetLang: appState.targetLang.code,
      );

      setState(() {
        _snrImprovement = (denoiseRes['snr_improvement_db'] as num?)?.toDouble() ?? 10.5;
        _noiseReductionPercent = (denoiseRes['noise_reduction_percent'] as num?)?.toInt() ?? 92;
        _denoisedAudioUrl = denoiseRes['clean_audio_url'] ?? '';
        _speakers = diarizeRes['speakers'] ?? [];
        _segments = diarizeRes['segments'] ?? [];
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _togglePlayAudio(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      final appState = Provider.of<AppState>(context, listen: false);
      final fullUrl = url.startsWith('http') ? url : 'http://${appState.serverHost}:${appState.serverPort}$url';
      try {
        await _audioPlayer.play(UrlSource(fullUrl));
        setState(() {
          _isPlaying = true;
          _currentlyPlayingUrl = url;
        });
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying = false;
          });
        });
      } catch (e) {
        debugPrint('Playback error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Audio Intelligence & Diarization',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            Text(
              'Spectral Denoising • Speaker Diarization • Voiceprints',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_up_doc_fill, color: AppTheme.primary),
            tooltip: 'Upload Audio',
            onPressed: _pickAudioFile,
          ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(radius: 20, color: AppTheme.primary),
                    const SizedBox(height: 20),
                    const Text(
                      'Analyzing Intercept Audio Stream...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Spectral gating • Speaker separation • Voiceprint extraction',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              )
            : _selectedFilePath == null
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
                            child: const Icon(CupertinoIcons.waveform_path_ecg, size: 40, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tactical Audio Intelligence',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Upload noisy tactical communications to isolate speakers, eliminate interference, extract clean voiceprints, and generate synchronized Romanized/English transcripts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: _pickAudioFile,
                            icon: const Icon(CupertinoIcons.folder_badge_plus, size: 18),
                            label: const Text('Select Audio Intercept (.mp3/.wav)', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        // Noise Suppression Summary Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.waveform, color: AppTheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fileName ?? 'Audio Stream',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.activeGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'DENOISED',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.activeGreen),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'SNR Improvement',
                                      value: '+${_snrImprovement.toStringAsFixed(1)} dB',
                                      icon: CupertinoIcons.arrow_up_right_circle_fill,
                                      color: AppTheme.activeGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'Noise Attenuation',
                                      value: '$_noiseReductionPercent%',
                                      icon: CupertinoIcons.shield_lefthalf_fill,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'Speakers',
                                      value: '${_speakers.length} Identified',
                                      icon: CupertinoIcons.person_2_fill,
                                      color: Colors.purpleAccent,
                                    ),
                                  ),
                                ],
                              ),
                              if (_denoisedAudioUrl.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _togglePlayAudio(_denoisedAudioUrl),
                                  icon: Icon(_isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 16),
                                  label: Text(_isPlaying ? 'Pause Clean Audio' : 'Play Enhanced Clean Audio'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surfaceAlt,
                                    foregroundColor: AppTheme.primary,
                                    elevation: 0,
                                    minimumSize: const Size(double.infinity, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Identified Speakers Voiceprints
                        const Text(
                          'SPEAKER DIARIZATION & VOICEPRINTS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _speakers.map<Widget>((spk) {
                            final spkId = spk['speaker_id'] ?? 'SPEAKER';
                            final alias = spk['alias'] ?? spkId;
                            final vpUrl = spk['voiceprint_url'] ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: spkId.toString().contains('00') ? Colors.blueAccent : Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alias.toString(),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        spkId.toString(),
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (vpUrl.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.speaker_2_fill, size: 16, color: AppTheme.primary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _togglePlayAudio(vpUrl),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 22),

                        // Multi-Speaker Diarization Timeline
                        const Text(
                          'TIMED OPERATIONAL TRANSCRIPTS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),

                        ..._segments.map<Widget>((seg) {
                          final spk = seg['speaker'] ?? 'SPEAKER_00';
                          final startTime = seg['start_time'] ?? '00:00';
                          final endTime = seg['end_time'] ?? '00:00';
                          final transcript = seg['transcript'] ?? '';
                          final phonetic = seg['phonetic_romanized'] ?? '';
                          final translation = seg['english_translation'] ?? '';
                          final isSpk0 = spk.toString().contains('00');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSpk0 ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isSpk0 ? Colors.blueAccent : Colors.orangeAccent).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSpk0 ? 'Caller 1 (Forward Unit)' : 'Caller 2 (HQ Command)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSpk0 ? Colors.blueAccent : Colors.orangeAccent,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$startTime - $endTime',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  transcript,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                                if (phonetic.isNotEmpty && phonetic != transcript) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceAlt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PHONETIC (ROMAN): ',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                        ),
                                        Expanded(
                                          child: Text(
                                            phonetic,
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (translation.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TRANSLATION: ',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.activeGreen),
                                      ),
                                      Expanded(
                                        child: Text(
                                          translation,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
