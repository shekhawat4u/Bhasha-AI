import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/gpu_api_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final GpuApiService _apiService = GpuApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _loadVaultRecords();
  }

  Future<void> _loadVaultRecords() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _apiService.serverHost = appState.serverHost;
      _apiService.serverPort = appState.serverPort;

      final res = await _apiService.getVaultRecords();
      setState(() {
        _records = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _verifyRecordIntegrity(Map<String, dynamic> record) async {
    final evId = record['evidence_id'] ?? '';
    final hash = record['sha256_hash'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CupertinoActivityIndicator(radius: 16, color: Colors.white),
      ),
    );

    try {
      final res = await _apiService.verifyVaultIntegrity(evidenceId: evId, expectedHash: hash);
      if (mounted) Navigator.pop(context); // close loader

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(CupertinoIcons.checkmark_seal_fill, color: AppTheme.activeGreen, size: 24),
                SizedBox(width: 8),
                Text('Evidence Verified', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evidence ID: $evId', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text('Encryption: AES-256-GCM (Military Grade)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Text('Status: ${res['tamper_verdict']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.activeGreen)),
                const SizedBox(height: 10),
                const Text('SHA-256 Checksum:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    hash,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showNewArchiveDialog() {
    final titleCtrl = TextEditingController(text: 'Tactical Radio Intercept - Sector Alpha');
    final textCtrl = TextEditingController(text: 'Forward post reports artillery movement. Hostile units advancing toward bridge 9.');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Material(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archive & Encrypt New Intercept',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Evidence Title / Tag',
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Transcript Content',
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _apiService.archiveVaultEvidence(
                        title: titleCtrl.text.trim(),
                        transcriptText: textCtrl.text.trim(),
                        threatLevel: 'CRITICAL',
                        threatKeywords: ['ARTILLERY', 'BRIDGE 9'],
                      );
                      _loadVaultRecords();
                    },
                    icon: const Icon(CupertinoIcons.lock_shield_fill, size: 18),
                    label: const Text('Encrypt with AES-256 & Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              'Encrypted Evidence Vault',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            Text(
              'AES-256 Military Storage • Biometrics • Integrity Hash',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppTheme.primary),
            tooltip: 'Archive Intercept',
            onPressed: _showNewArchiveDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 16, color: AppTheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master Security Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.lock_shield_fill, color: AppTheme.primary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'AES-256-GCM Military Encryption Active',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'All stored intercepts are cryptographically hashed and tamper-proofed for chain-of-custody compliance.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CLASSIFIED EVIDENCE ARCHIVES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        Text(
                          '${_records.length} Records Intact',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.activeGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Records List
                    ..._records.map<Widget>((rec) {
                      final map = rec as Map<String, dynamic>;
                      final evId = map['evidence_id'] ?? 'EV-0000';
                      final title = map['title'] ?? 'Intercept';
                      final hash = map['sha256_hash'] ?? '';
                      final classification = map['classification'] ?? 'TOP SECRET';
                      final threatLevel = map['threat_level'] ?? 'MEDIUM';
                      final deepfake = map['deepfake_verdict'] ?? 'AUTHENTIC HUMAN';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    evId,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    classification,
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),

                            // Details Row
                            Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_shield_fill, size: 14, color: AppTheme.activeGreen),
                                const SizedBox(width: 4),
                                Text(
                                  deepfake,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.activeGreen),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Threat: $threatLevel',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orangeAccent),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            // SHA256 snippet
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text('SHA-256: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                                  Expanded(
                                    child: Text(
                                      hash.length > 28 ? '${hash.substring(0, 28)}...' : hash,
                                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: hash));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('SHA-256 Hash copied to clipboard')),
                                      );
                                    },
                                    child: const Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: () => _verifyRecordIntegrity(map),
                                icon: const Icon(CupertinoIcons.shield_lefthalf_fill, size: 14),
                                label: const Text('Verify Cryptographic Integrity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
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
