import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/document_page.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/language_pill.dart';
import 'language_sheet.dart';
import 'settings_sheet.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final docs = appState.attachedDocuments;
    final activeIndex = appState.selectedDocumentIndex;
    final doc = appState.attachedDocument;

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
                          child: Text(
                            docs.length > 1 ? '${docs.length} PDFS' : 'DOCS',
                            style: const TextStyle(
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

              // Language Selector
              Center(
                child: LanguagePill(
                  sourceLang: appState.sourceLang,
                  targetLang: appState.targetLang,
                  onSourceTap: () => LanguageSheet.show(context, isSource: true),
                  onTargetTap: () => LanguageSheet.show(context, isSource: false),
                  onSwapTap: () => appState.swapLanguages(),
                ),
              ),

              const SizedBox(height: 14),

              // Multi-Document Selector Tabs / Bar
              if (docs.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length + 1,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      if (idx == docs.length) {
                        // "+ Add PDF" button
                        return ActionChip(
                          avatar: const Icon(CupertinoIcons.plus, size: 14, color: AppTheme.primary),
                          label: const Text('Add PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          backgroundColor: AppTheme.surfaceAlt,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3))),
                          onPressed: () => appState.pickAndTranslateDocument(append: true),
                        );
                      }

                      final isSelected = idx == activeIndex;
                      final d = docs[idx];
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (_) => appState.selectDocument(idx),
                        avatar: Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 14,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              d.fileName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${d.pageCount}p)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppTheme.textMuted,
                              ),
                            ),
                            if (docs.length > 1) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => appState.removeDocumentAt(idx),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: 13,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceAlt,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Active Document Card Header
              if (doc != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doc.pageCount} pages • Document ${activeIndex + 1} of ${docs.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (docs.length > 1) {
                            appState.removeDocumentAt(activeIndex);
                          } else {
                            appState.removeAttachedDocument();
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: AppTheme.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Page by page preview
              Expanded(
                child: appState.isTranslating
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Translating document pages on GPU...',
                              style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : doc == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.doc_on_clipboard, size: 40, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text('No Documents Attached', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => appState.pickAndTranslateDocument(),
                                  icon: const Icon(CupertinoIcons.plus, size: 16),
                                  label: const Text('Add PDF(s)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ...doc.pages.map((page) => _buildPageItem(context, page)),
                            ],
                          ),
              ),

              // Bottom Actions: [ Translate all pages ] + Share
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          appState.retranslateAttachedDocument();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Translating all ${doc?.pageCount ?? 1} pages into ${appState.targetLang.name} on GPU...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Translate All into ${appState.targetLang.name}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () => appState.pickAndTranslateDocument(append: true),
                        icon: const Icon(CupertinoIcons.plus, size: 20, color: AppTheme.primary),
                        tooltip: 'Add More PDFs',
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

  Widget _buildPageItem(BuildContext context, DocumentPage page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAGE ${page.pageNumber}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: page.translatedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Page ${page.pageNumber} translation copied!'),
                      duration: const Duration(seconds: 1),
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
          const SizedBox(height: 8),
          Text(
            page.originalText,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.translatedText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.35,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
