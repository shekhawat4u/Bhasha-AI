import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/gpu_api_service.dart';

class StratComnScreen extends StatefulWidget {
  const StratComnScreen({super.key});

  @override
  State<StratComnScreen> createState() => _StratComnScreenState();
}

class _StratComnScreenState extends State<StratComnScreen> {
  final GpuApiService _apiService = GpuApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _briefController = TextEditingController();

  String _selectedLang = 'hi';
  int _durationSec = 30;
  String _selectedProfile = 'military_radio';
  bool _isGenerating = false;
  bool _isCloning = false;
  bool _isPlaying = false;

  Map<String, dynamic>? _generatedScript;
  String? _broadcastAudioUrl;

  final List<Map<String, String>> _templates = [
    {
      'title': 'Tactical Ceasefire Order',
      'brief': 'Ceasefire instruction to hostile forward battalion in Sector 4 to retreat to safe demarcation line immediately.',
    },
    {
      'title': 'Convoy Disinformation',
      'brief': 'Radio directive informing hostile unit that bridge sector 9 is mined and all logistical armor must divert west.',
    },
    {
      'title': 'Psychological Broadcast',
      'brief': 'Surrender broadcast to isolated enemy squad with guarantee of medical aid and safe passage.',
    },
    {
      'title': 'Border Patrol Check-in',
      'brief': 'Routine situation report on northern perimeter checkpoint observing suspicious drone movement.',
    },
  ];

  final List<Map<String, dynamic>> _acousticProfiles = [
    {
      'id': 'military_radio',
      'name': 'PRC-117 Military Radio',
      'desc': '300-3400Hz Bandpass, Roger Beep, Squelch Burst',
      'icon': CupertinoIcons.antenna_radiowaves_left_right,
    },
    {
      'id': 'walkie_talkie',
      'name': 'Tactical Walkie-Talkie',
      'desc': 'VHF/UHF hiss, compression & click',
      'icon': CupertinoIcons.radiowaves_right,
    },
    {
      'id': 'megaphone_echo',
      'name': 'Long-Range PA Megaphone',
      'desc': 'Acoustic dispersion, 120ms slapback echo',
      'icon': CupertinoIcons.speaker_2_fill,
    },
    {
      'id': 'telephone_8k',
      'name': 'Intercepted Telephone',
      'desc': '8kHz PSTN narrowband line',
      'icon': CupertinoIcons.phone_fill,
    },
    {
      'id': 'armored_vehicle',
      'name': 'Armored Cockpit / Tank',
      'desc': 'Diesel turbine rumble & cabin resonance',
      'icon': CupertinoIcons.car_detailed,
    },
  ];

  @override
  void initState() {
    super.initState();
    _briefController.text = _templates.first['brief']!;
  }

  @override
  void dispose() {
    _briefController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateScript() async {
    if (_briefController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      final res = await _apiService.generateTacticalScript(
        scenarioBrief: _briefController.text.trim(),
        targetLang: _selectedLang,
        durationTargetSec: _durationSec,
        acousticProfile: _selectedProfile,
      );

      setState(() {
        _generatedScript = res;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _cloneAndSynthesize() async {
    if (_generatedScript == null) return;
    final dialogues = (_generatedScript!['dialogues'] as List<dynamic>?) ?? [];
    if (dialogues.isEmpty) return;

    final fullText = dialogues.map((d) => "${d['speaker']}: ${d['line']}").join(". ");

    setState(() {
      _isCloning = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      final res = await _apiService.cloneTacticalVoice(
        text: fullText,
        language: _selectedLang,
        acousticProfile: _selectedProfile,
      );

      setState(() {
        _broadcastAudioUrl = res['audio_url'];
        _isCloning = false;
      });

      if (_broadcastAudioUrl != null && _broadcastAudioUrl!.isNotEmpty) {
        _playBroadcastAudio(_broadcastAudioUrl!);
      }
    } catch (e) {
      setState(() {
        _isCloning = false;
      });
    }
  }

  void _playBroadcastAudio(String url) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final fullUrl = url.startsWith('http') ? url : 'http://${appState.serverHost}:${appState.serverPort}$url';
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(UrlSource(fullUrl));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      debugPrint('Playback error: $e');
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
              'Tactical Broadcast & RF Studio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            Text(
              'Scenario Scripting • Voice Cloning • RF Simulation',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Preset Chips
              const Text(
                'TACTICAL BRIEF TEMPLATES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _templates.map((tpl) {
                    final isSel = _briefController.text == tpl['brief'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(tpl['title']!),
                        backgroundColor: isSel ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceAlt,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                        side: BorderSide(
                          color: isSel ? AppTheme.primary : AppTheme.border,
                        ),
                        onPressed: () {
                          setState(() {
                            _briefController.text = tpl['brief']!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Scenario Brief Input
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operational Scenario Brief',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _briefController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter mission brief, objectives, speaker roles...',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: AppTheme.surfaceAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Controls Row (Language + Target Duration)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Language', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLang,
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppTheme.surfaceAlt,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'hi', child: Text('Hindi (हिंदी)')),
                                  DropdownMenuItem(value: 'ur', child: Text('Urdu (اردو)')),
                                  DropdownMenuItem(value: 'zh', child: Text('Mandarin (中文)')),
                                  DropdownMenuItem(value: 'pa', child: Text('Punjabi (ਪੰਜਾਬੀ)')),
                                  DropdownMenuItem(value: 'bn', child: Text('Bengali (বাংলা)')),
                                  DropdownMenuItem(value: 'en', child: Text('English (Tactical)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedLang = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration: ${_durationSec}s', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              Slider(
                                value: _durationSec.toDouble(),
                                min: 15,
                                max: 90,
                                divisions: 5,
                                activeColor: AppTheme.primary,
                                onChanged: (val) {
                                  setState(() => _durationSec = val.toInt());
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tactical Acoustic Profile Selector
              const Text(
                'TACTICAL ACOUSTIC RF SIMULATOR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              ..._acousticProfiles.map((prof) {
                final isSel = _selectedProfile == prof['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? AppTheme.primary : AppTheme.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primary : AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(prof['icon'] as IconData, size: 18, color: isSel ? Colors.white : AppTheme.primary),
                    ),
                    title: Text(
                      prof['name']!,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSel ? AppTheme.primary : AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      prof['desc']!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    trailing: Icon(
                      isSel ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: isSel ? AppTheme.primary : AppTheme.textMuted,
                      size: 20,
                    ),
                    onTap: () {
                      setState(() => _selectedProfile = prof['id']!);
                    },
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateScript,
                  icon: _isGenerating
                      ? const CupertinoActivityIndicator(color: Colors.white, radius: 10)
                      : const Icon(CupertinoIcons.sparkles, size: 18),
                  label: Text(
                    _isGenerating ? 'Synthesizing Tactical Dialogues...' : 'Generate Multi-Speaker Timed Script',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              if (_generatedScript != null) ...[
                const SizedBox(height: 24),
                // Generated Script Container
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _generatedScript!['title'] ?? 'Generated Dialogue',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedProfile.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dialogues List
                      ...((_generatedScript!['dialogues'] as List<dynamic>?) ?? []).map<Widget>((d) {
                        final spk = d['speaker'] ?? 'Speaker';
                        final time = d['time'] ?? '00:00';
                        final line = d['line'] ?? '';
                        final isFirst = spk.toString().contains('1') || spk.toString().contains('Alpha');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFirst ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    spk,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isFirst ? Colors.blueAccent : Colors.orangeAccent,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                line,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      // Voice Clone & Acoustic Broadcast Engine
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCloning ? null : _cloneAndSynthesize,
                          icon: _isCloning
                              ? const CupertinoActivityIndicator(color: Colors.white, radius: 10)
                              : Icon(_isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid, size: 16),
                          label: Text(
                            _isCloning
                                ? 'Cloning & Applying RF FX...'
                                : (_broadcastAudioUrl != null
                                    ? (_isPlaying ? 'Pause Broadcast Audio' : 'Play Synthesized Tactical Broadcast')
                                    : 'Synthesize Voice & Simulate RF Transmission'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.activeGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
