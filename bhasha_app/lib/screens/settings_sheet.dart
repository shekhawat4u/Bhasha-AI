import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 14),

            // Device Connection Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appState.isGpuConnected ? AppTheme.activeGreen : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backend',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appState.serverHost}:${appState.serverPort} • ${appState.isGpuConnected ? "Connected" : "Offline"}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showServerEditDialog(context, appState),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Re-pair',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Indian Languages Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: appState.isIndianLanguagesMode ? AppTheme.primaryLight.withValues(alpha: 0.35) : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: appState.isIndianLanguagesMode ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.2) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Indian languages',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      CupertinoSwitch(
                        value: appState.isIndianLanguagesMode,
                        activeTrackColor: AppTheme.activeGreen,
                        onChanged: (val) => appState.setIndianLanguagesMode(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.isIndianLanguagesMode
                        ? 'Active: Transcription and translation enabled across 22 Indian languages.'
                        : 'Enable transcription and translation for 22 Indian languages.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Speech Output
            _buildSettingRow(
              title: 'Speech output',
              value: appState.speechOutput,
              onTap: () => _showSpeechOutputDialog(context, appState),
            ),
            const Divider(height: 1, color: AppTheme.surfaceMuted),

            // Keep Transcripts
            _buildSettingRow(
              title: 'Keep transcripts',
              value: appState.keepTranscripts,
              onTap: () => _showKeepTranscriptsDialog(context, appState),
            ),

            const SizedBox(height: 20),

            // Done Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPill,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 13, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeechOutputDialog(BuildContext context, AppState appState) {
    String selectedGender = appState.speechVoiceGender;
    double selectedSpeed = appState.speechPlaybackSpeed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final voiceOptions = [
            {'key': 'female', 'title': 'Female', 'desc': 'Natural, clear voice synthesis'},
            {'key': 'male', 'title': 'Male', 'desc': 'Deep, resonant voice profile'},
            {'key': 'tactical', 'title': 'Tactical Radio', 'desc': 'Tactical communication filter (400-3400Hz)'},
          ];
          final speeds = [0.75, 1.0, 1.25, 1.5];

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Speech Output Settings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 18, color: AppTheme.textMuted),
                      onPressed: () {
                        appState.stopSpeech();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'VOICE PROFILE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ...voiceOptions.map((opt) {
                  final isSelected = selectedGender == opt['key'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      title: Text(
                        opt['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        opt['desc']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary, size: 20)
                          : const Icon(CupertinoIcons.circle, color: AppTheme.textMuted, size: 20),
                      onTap: () {
                        setModalState(() {
                          selectedGender = opt['key']!;
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text(
                  'PLAYBACK SPEED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: speeds.map((spd) {
                    final isSpdSelected = selectedSpeed == spd;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedSpeed = spd;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSpdSelected ? AppTheme.darkPill : AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$spd×',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSpdSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Preview test
                          appState.updateSpeechSettings(gender: selectedGender, speed: selectedSpeed);
                          final testPhrase = appState.targetLang.code == 'ta'
                              ? 'வணக்கம், இது பேச்சு சோதனை.'
                              : (appState.targetLang.code == 'hi'
                                  ? 'नमस्ते, यह आवाज़ का परीक्षण है।'
                                  : 'This is a tactical speech output test.');
                          appState.speakText(testPhrase, langCode: appState.targetLang.code);
                        },
                        icon: const Icon(CupertinoIcons.play_arrow, size: 16),
                        label: const Text('Test Voice'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          appState.updateSpeechSettings(gender: selectedGender, speed: selectedSpeed);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkPill,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Voice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showKeepTranscriptsDialog(BuildContext context, AppState appState) {
    final options = ['24 hours', '7 days', '30 days', 'Forever'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep Transcripts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final isSelected = appState.keepTranscripts == opt;
              return ListTile(
                dense: true,
                title: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary, size: 20)
                    : null,
                onTap: () {
                  appState.updateSettings(keepTranscripts: opt);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showServerEditDialog(BuildContext context, AppState appState) {
    final hostController = TextEditingController(text: appState.serverHost);
    final portController = TextEditingController(text: appState.serverPort.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure GPU Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              decoration: const InputDecoration(labelText: 'GPU Host IP / Domain', hintText: '172.16.136.120'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port', hintText: '8000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              appState.updateServerConfig(
                hostController.text.trim(),
                int.tryParse(portController.text.trim()) ?? 8000,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}
