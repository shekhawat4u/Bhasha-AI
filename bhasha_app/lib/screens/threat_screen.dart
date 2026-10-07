import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/gpu_api_service.dart';

class ThreatScreen extends StatefulWidget {
  const ThreatScreen({super.key});

  @override
  State<ThreatScreen> createState() => _ThreatScreenState();
}

class _ThreatScreenState extends State<ThreatScreen> {
  final GpuApiService _apiService = GpuApiService();
  final TextEditingController _textController = TextEditingController();

  bool _isScanning = false;
  String? _fileName;
  Map<String, dynamic>? _threatResult;

  final List<String> _sampleIntercepts = [
    'Enemy forward battalion is moving heavy artillery and mortar toward Sector 4 bridge. Immediate airstrike requested.',
    'Commander Alpha, drone spotted hovering over Northern Checkpost grid 42.1. Prepare anti-air battery and hold position.',
    'Hostile squad initiated ambush near Ridge 9. Suppressive gunfire reported, requesting immediate ammunition reinforcements and withdrawal corridor.',
    'Routine perimeter patrol completed. No suspicious signals or hostile movement observed in Sector 2.',
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = _sampleIntercepts.first;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _scanText() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _isScanning = true;
      _fileName = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      final res = await _apiService.scanThreatKeywords(text: _textController.text.trim());
      setState(() {
        _threatResult = res;
        _isScanning = false;
      });
    } catch (_) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickAndScanAudio() async {
    final appState = Provider.of<AppState>(context, listen: false);
    _apiService.serverHost = appState.serverHost;
    _apiService.serverPort = appState.serverPort;

    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.path != null) {
        setState(() {
          _isScanning = true;
          _fileName = result.name;
        });

        final res = await _apiService.scanThreatAudio(filePath: result.path!);
        if (!mounted) return;
        setState(() {
          _threatResult = res;
          if (res['full_transcript'] != null) {
            _textController.text = res['full_transcript'];
          }
          _isScanning = false;
        });
      }
    } catch (_) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threatLevel = _threatResult?['threat_level'] ?? 'CLEAR';
    final alertTriggered = _threatResult?['alert_triggered'] ?? false;
    final totalThreats = _threatResult?['total_threats_detected'] ?? 0;
    final threatList = (_threatResult?['threat_list'] as List<dynamic>?) ?? [];
    final timecodedThreats = (_threatResult?['timecoded_threats'] as List<dynamic>?) ?? [];
    final categories = (_threatResult?['threat_categories'] as Map<String, dynamic>?) ?? {};

    final isCritical = threatLevel == 'CRITICAL';
    final isHigh = threatLevel == 'HIGH';
    final alertColor = isCritical ? Colors.redAccent : (isHigh ? Colors.orangeAccent : (alertTriggered ? Colors.amber : AppTheme.activeGreen));

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
              'Threat Keyword Interceptor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            Text(
              'Real-Time Tactical Danger Detection & Alarms',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.waveform_circle_fill, color: AppTheme.primary),
            tooltip: 'Probe Audio File',
            onPressed: _pickAndScanAudio,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intercept Presets
              const Text(
                'TACTICAL INTERCEPT PRESETS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sampleIntercepts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final text = entry.value;
                    final isSel = _textController.text == text;
                    final titles = ['Artillery Movement', 'Drone / Checkpost', 'Ambush & Ammo', 'Routine Clear Patrol'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(titles[idx]),
                        backgroundColor: isSel ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceAlt,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                        side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.border),
                        onPressed: () {
                          setState(() {
                            _textController.text = text;
                            _fileName = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Input Box
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transmission Transcript to Scan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        if (_fileName != null)
                          Text(
                            _fileName!,
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter intercepted audio transcript or words...',
                        filled: true,
                        fillColor: AppTheme.surfaceAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanText,
                            icon: _isScanning
                                ? const CupertinoActivityIndicator(color: Colors.white, radius: 10)
                                : const Icon(CupertinoIcons.search, size: 16),
                            label: Text(_isScanning ? 'Scanning...' : 'Scan Transcript for Threats'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _pickAndScanAudio,
                          icon: const Icon(CupertinoIcons.folder_badge_plus, color: AppTheme.primary),
                          tooltip: 'Select Audio File',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceAlt,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_threatResult != null) ...[
                const SizedBox(height: 20),

                // Radar Alert Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: alertColor, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            alertTriggered ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.checkmark_shield_fill,
                            color: alertColor,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            alertTriggered ? 'THREAT LEVEL: $threatLevel' : 'TRANSMISSION CLEAR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: alertColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _threatResult!['tactical_advisory'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: alertColor.withValues(alpha: 0.9),
                        ),
                      ),
                      if (alertTriggered) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '$totalThreats Flagged Threat Keywords Detected',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'THREAT CATEGORY BREAKDOWN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.entries.map((c) {
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
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c.key,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${c.value}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (threatList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'FLAGGED THREAT KEYWORDS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: threatList.map<Widget>((t) {
                      final kw = t['keyword'] ?? '';
                      final cat = t['category'] ?? '';
                      final sev = t['severity'] ?? 'MEDIUM';
                      final col = sev == 'CRITICAL' ? Colors.redAccent : (sev == 'HIGH' ? Colors.orangeAccent : Colors.amber);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: col.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kw,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: col),
                            ),
                            Text(
                              cat,
                              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (timecodedThreats.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'TIMECODED TACTICAL SIGHTINGS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  ...timecodedThreats.map<Widget>((tt) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tt['timestamp'] ?? '00:00',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.redAccent, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keyword: ${tt['keyword']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tt['sentence'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
