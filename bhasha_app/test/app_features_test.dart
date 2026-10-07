import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhasha_app/main.dart';
import 'package:bhasha_app/state/app_state.dart';
import 'package:bhasha_app/models/language.dart';

void main() {
  test('AppState Audio, Document, and Video workflow tests', () async {
    final appState = AppState();

    // 1. Test sample audio loading and translation
    appState.loadSampleAudio();
    expect(appState.attachedAudio, isNotNull);
    expect(appState.attachedAudio!.fileName, contains('1.mp3'));
    expect(appState.attachedAudio!.sourceText, contains('装载机'));
    expect(appState.attachedAudio!.tacticalMatches.isNotEmpty, isTrue);

    // 2. Test sample document loading and translation
    appState.loadSampleDocument();
    expect(appState.attachedDocument, isNotNull);
    expect(appState.attachedDocuments.length, 2);
    expect(appState.attachedDocument!.fileName, 'service_manual_v4.pdf');
    expect(appState.attachedDocument!.pages.length, 2);

    // 3. Test sample video loading and subtitles
    appState.loadSampleVideo();
    expect(appState.attachedVideo, isNotNull);
    expect(appState.attachedVideo!.videoTitle, 'LINE_INSPECTION.MP4');
    expect(appState.attachedVideo!.subtitles.length, 3);

    // 4. Test dynamic target language update across all attached media
    appState.setTargetLanguage(const Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'));
    expect(appState.targetLang.code, 'hi');
  });

  testWidgets('Attachment BottomSheet contains Audio, PDF, and Video options', (WidgetTester tester) async {
    await tester.pumpWidget(const BhashaApp());

    // Advance splash screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Tap the attachment paperclip icon
    final paperclip = find.byIcon(CupertinoIcons.paperclip);
    expect(paperclip, findsOneWidget);
    await tester.tap(paperclip);
    await tester.pumpAndSettle();

    // Verify all 3 media translation options are present
    expect(find.text('Translate Media / File'), findsOneWidget);
    expect(find.text('Audio File Translation'), findsOneWidget);
    expect(find.text('PDF / Document Translation'), findsOneWidget);
    expect(find.text('Video / Media Subtitling'), findsOneWidget);
  });
}
