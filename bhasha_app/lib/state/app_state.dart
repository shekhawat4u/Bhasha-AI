import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../models/language.dart';
import '../models/translation_result.dart';
import '../models/document_page.dart';
import '../models/video_subtitle.dart';
import '../models/audio_file_translation.dart';
import '../services/gpu_api_service.dart';
import '../services/gpu_stream_service.dart';

class AppState extends ChangeNotifier {
  final GpuApiService _apiService = GpuApiService();
  final GpuStreamService _streamService = GpuStreamService();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordStreamSubscription;
  StreamSubscription<TranslationResult>? _streamServiceSubscription;

  Language _sourceLang = const Language(code: 'en', name: 'English', nativeName: 'English');
  Language _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');


  bool _isGpuConnected = false;
  bool _isListening = false;
  bool _detectLanguage = true;
  String _serverHost = '192.168.0.141';
  int _serverPort = 8000;
  String _noiseReduction = 'High';
  String _modelSet = 'Tactical Neural Engine';
  String _speechVoiceGender = 'female'; // 'female', 'male', 'tactical'
  double _speechPlaybackSpeed = 1.0; // 0.75, 1.0, 1.25, 1.5
  String _keepTranscripts = '7 days';

  bool _isPlayingTts = false;
  String? _currentSpeakingText;

  int _listeningSeconds = 0;
  Timer? _listeningTimer;
  Timer? _visualizerTimer;
  List<double> _visualizerBars = List.filled(12, 0.2);

  bool _isTranslating = false;

  TranslationResult _currentResult = TranslationResult(
    sourceText: '',
    translatedText: '',
    sourceLang: 'en',
    targetLang: 'en',
    detectedLang: '',
    latencyMs: 0,
  );

  AudioFileTranslation? _attachedAudio;
  List<DocumentTranslation> _attachedDocuments = [];
  int _selectedDocumentIndex = 0;
  VideoMediaTranslation? _attachedVideo;
  bool _isIndianLanguagesMode = false;
  List<LiveSegment> _liveSegments = [];

  // Getters
  bool get isIndianLanguagesMode => _isIndianLanguagesMode;
  List<LiveSegment> get liveSegments => _liveSegments;
  Language get sourceLang => _sourceLang;
  Language get targetLang => _targetLang;
  List<DocumentTranslation> get attachedDocuments => _attachedDocuments;
  int get selectedDocumentIndex => _selectedDocumentIndex;
  DocumentTranslation? get attachedDocument => _attachedDocuments.isNotEmpty
      ? _attachedDocuments[_selectedDocumentIndex.clamp(0, _attachedDocuments.length - 1)]
      : null;
  bool get isGpuConnected => _isGpuConnected;
  bool get isListening => _isListening;
  bool get isTranslating => _isTranslating;
  bool get detectLanguage => _detectLanguage;
  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  String get noiseReduction => _noiseReduction;
  String get modelSet => _modelSet;
  String get speechVoiceGender => _speechVoiceGender;
  double get speechPlaybackSpeed => _speechPlaybackSpeed;
  String get speechOutput {
    final profile = _speechVoiceGender == 'tactical'
        ? 'Tactical Radio'
        : (_speechVoiceGender == 'male' ? 'Male' : 'Female');
    return '$profile - $_speechPlaybackSpeed×';
  }
  bool get isPlayingTts => _isPlayingTts;
  String? get currentSpeakingText => _currentSpeakingText;
  String get keepTranscripts => _keepTranscripts;
  int get listeningSeconds => _listeningSeconds;
  List<double> get visualizerBars => _visualizerBars;
  TranslationResult get currentResult => _currentResult;
  bool get isGeneratingGist => _isGeneratingGist;
  bool _isGeneratingGist = false;
  AudioFileTranslation? get attachedAudio => _attachedAudio;
  VideoMediaTranslation? get attachedVideo => _attachedVideo;

  AppState() {
    _initConnection();
    _initTtsPlayer();
  }

  void _initTtsPlayer() {
    _ttsPlayer.onPlayerComplete.listen((_) {
      _isPlayingTts = false;
      _currentSpeakingText = null;
      notifyListeners();
    });
    _ttsPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        _isPlayingTts = false;
        _currentSpeakingText = null;
        notifyListeners();
      }
    });
  }

  Future<void> _initConnection() async {
    _isGpuConnected = await _apiService.checkServerHealth();
    _serverHost = _apiService.serverHost;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    _isGpuConnected = await _apiService.checkServerHealth();
    _serverHost = _apiService.serverHost;
    notifyListeners();
  }

  void updateServerConfig(String host, int port) {
    _serverHost = host;
    _serverPort = port;
    _apiService.serverHost = host;
    _apiService.serverPort = port;
    checkConnection();
  }

  void setIndianLanguagesMode(bool enabled) {
    _isIndianLanguagesMode = enabled;
    if (enabled) {
      final isSourceIndic = Language.indicLanguages.any((l) => l.code == _sourceLang.code);
      final isTargetIndic = Language.indicLanguages.any((l) => l.code == _targetLang.code);
      if (!isSourceIndic) {
        _sourceLang = const Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी');
      }
      if (!isTargetIndic) {
        _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');
      }
    } else {
      final isSourceAll = Language.allLanguages.any((l) => l.code == _sourceLang.code);
      final isTargetAll = Language.allLanguages.any((l) => l.code == _targetLang.code);
      if (!isSourceAll) {
        _sourceLang = const Language(code: 'zh', name: 'Chinese', nativeName: '中文 (Mandarin)');
      }
      if (!isTargetAll) {
        _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');
      }
    }
    notifyListeners();
  }

  void updateSettings({
    String? noiseReduction,
    String? modelSet,
    bool? detectLanguage,
    String? keepTranscripts,
  }) {
    if (noiseReduction != null) _noiseReduction = noiseReduction;
    if (modelSet != null) _modelSet = modelSet;
    if (detectLanguage != null) _detectLanguage = detectLanguage;
    if (keepTranscripts != null) _keepTranscripts = keepTranscripts;
    notifyListeners();
  }

  void setSourceLanguage(Language lang) {
    _sourceLang = lang;
    notifyListeners();
    if (_isListening && _isGpuConnected) {
      _streamService.connect(
        _serverHost,
        _serverPort,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        useIndic: _isIndianLanguagesMode,
      );
    }
  }

  void setTargetLanguage(Language lang) {
    _targetLang = lang;
    notifyListeners();
    if (_currentResult.sourceText.isNotEmpty) {
      translateInputText(_currentResult.sourceText);
    }
    if (_isListening && _isGpuConnected) {
      _streamService.connect(
        _serverHost,
        _serverPort,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        useIndic: _isIndianLanguagesMode,
      );
    }
    if (_attachedAudio != null) {
      retranslateAttachedAudio();
    }
    if (_attachedDocuments.isNotEmpty) {
      retranslateAttachedDocument();
    }
    if (_attachedVideo != null) {
      retranslateAttachedVideo();
    }
  }

  void swapLanguages() {
    final temp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = temp;
    notifyListeners();
    if (_currentResult.sourceText.isNotEmpty) {
      translateInputText(_currentResult.sourceText);
    }
    if (_isListening && _isGpuConnected) {
      _streamService.connect(
        _serverHost,
        _serverPort,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        useIndic: _isIndianLanguagesMode,
      );
    }
    if (_attachedAudio != null) {
      retranslateAttachedAudio();
    }
    if (_attachedDocuments.isNotEmpty) {
      retranslateAttachedDocument();
    }
    if (_attachedVideo != null) {
      retranslateAttachedVideo();
    }
  }


  Future<void> startListening({String? demoLang}) async {
    _isListening = true;
    _listeningSeconds = 0;
    _liveSegments.clear();

    _currentResult = TranslationResult(
      sourceText: 'Listening...',
      translatedText: 'Translating in real-time...',
      sourceLang: _sourceLang.code,
      targetLang: _targetLang.code,
      detectedLang: _sourceLang.name,
      latencyMs: 25,
      segments: [],
    );
    notifyListeners();

    _listeningTimer?.cancel();
    _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _listeningSeconds++;
      notifyListeners();
    });

    final random = Random();
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _visualizerBars = List.generate(12, (index) => 0.15 + random.nextDouble() * 0.75);
      notifyListeners();
    });

    // 1. Connect to WebSocket stream on GPU server
    if (_isGpuConnected) {
      final connected = await _streamService.connect(
        _serverHost,
        _serverPort,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        useIndic: _isIndianLanguagesMode,
      );

      if (connected) {
        _streamServiceSubscription?.cancel();
        _streamServiceSubscription = _streamService.stream.listen((res) {
          if (res.segments.isNotEmpty) {
            if (res.segments.length >= _liveSegments.length) {
              _liveSegments = List<LiveSegment>.from(res.segments);
            } else {
              final activeIncoming = res.segments.last;
              if (_liveSegments.isNotEmpty) {
                final lastExisting = _liveSegments.last;
                if (lastExisting.sourceText == activeIncoming.sourceText) {
                  _liveSegments[_liveSegments.length - 1] = activeIncoming;
                } else if (!lastExisting.sourceText.contains(activeIncoming.sourceText) &&
                           !activeIncoming.sourceText.contains(lastExisting.sourceText)) {
                  _liveSegments.add(activeIncoming);
                } else {
                  _liveSegments[_liveSegments.length - 1] = activeIncoming;
                }
              } else {
                _liveSegments = List<LiveSegment>.from(res.segments);
              }
            }
            _currentResult = res;
            notifyListeners();
          } else if (res.sourceText.isNotEmpty || res.translatedText.isNotEmpty) {
            if (_liveSegments.isEmpty) {
              _liveSegments.add(LiveSegment(
                sourceText: res.sourceText,
                translatedText: res.translatedText,
                detectedLang: res.detectedLang,
              ));
            } else {
              _liveSegments[_liveSegments.length - 1] = LiveSegment(
                sourceText: res.sourceText,
                translatedText: res.translatedText,
                detectedLang: res.detectedLang,
              );
            }
            _currentResult = res;
            notifyListeners();
          }
        });
      }
    }

    // 2. Start recording live mic audio chunks and stream to backend
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        final audioStream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        _recordStreamSubscription?.cancel();
        _recordStreamSubscription = audioStream.listen((chunk) {
          if (_isListening) {
            _streamService.sendAudioChunk(chunk);
            _updateVisualizerFromPcm(chunk);
          }
        });
      }
    } catch (e) {
      debugPrint("Live mic recording exception: $e");
    }

    notifyListeners();
  }

  void _updateVisualizerFromPcm(Uint8List bytes) {
    if (bytes.isEmpty) return;
    int sum = 0;
    final numSamples = bytes.length ~/ 2;
    for (int i = 0; i < bytes.length - 1; i += 2) {
      int sample = bytes[i] | (bytes[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      sum += (sample * sample) ~/ 1000;
    }
    final rms = sqrt(sum / (numSamples > 0 ? numSamples : 1)) / 1000.0;
    final amp = rms.clamp(0.1, 1.0);
    final random = Random();
    _visualizerBars = List.generate(12, (index) => (amp * (0.4 + random.nextDouble() * 0.6)).clamp(0.15, 1.0));
    notifyListeners();
  }

  Future<void> stopListening() async {
    _isListening = false;
    _listeningTimer?.cancel();
    _visualizerTimer?.cancel();
    _visualizerBars = List.filled(12, 0.2);

    try {
      await _recordStreamSubscription?.cancel();
      _recordStreamSubscription = null;
      await _audioRecorder.stop();
    } catch (_) {}

    _streamService.flush();
    _streamService.disconnect();
    _streamServiceSubscription?.cancel();
    _streamServiceSubscription = null;

    if (_liveSegments.isNotEmpty) {
      final combinedSource = _liveSegments.map((s) => s.sourceText.trim()).where((t) => t.isNotEmpty).join(". ");
      final combinedTrans = _liveSegments.map((s) => s.translatedText.trim()).where((t) => t.isNotEmpty).join(". ");
      final lastDetected = _liveSegments.last.detectedLang;
      _currentResult = TranslationResult(
        sourceText: combinedSource.isNotEmpty ? (combinedSource.endsWith('.') ? combinedSource : '$combinedSource.') : '',
        translatedText: combinedTrans.isNotEmpty ? (combinedTrans.endsWith('.') ? combinedTrans : '$combinedTrans.') : '',
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        detectedLang: lastDetected.isNotEmpty ? lastDetected : _sourceLang.name,
        latencyMs: 25,
        segments: List<LiveSegment>.from(_liveSegments),
      );
    } else if (_currentResult.sourceText == 'Listening...') {
      _currentResult = TranslationResult(
        sourceText: '',
        translatedText: '',
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
      );
    }
    notifyListeners();
  }


  Future<void> translateInputText(String text) async {
    if (text.trim().isEmpty) return;
    
    _isTranslating = true;
    _currentResult = TranslationResult(
      sourceText: text,
      translatedText: '',
      sourceLang: _sourceLang.code,
      targetLang: _targetLang.code,
    );
    notifyListeners();

    String effectiveSource = _sourceLang.code;
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    if (hasChinese && (effectiveSource == 'en' || effectiveSource == 'auto')) {
      effectiveSource = 'zh';
    }

    final res = await _apiService.translateText(
      text: text,
      sourceLang: effectiveSource,
      targetLang: _targetLang.code == effectiveSource ? (_targetLang.code == 'en' ? 'zh' : 'en') : _targetLang.code,
      isIndic: _isIndianLanguagesMode,
    );
    _currentResult = res;
    _isTranslating = false;
    notifyListeners();
  }

  // ==========================================
  // AUDIO FILE TRANSLATION
  // ==========================================

  Future<bool> pickAndTranslateAudio() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus'],
      );

      if (result != null && result.path != null) {
        final filePath = result.path!;
        final fileName = result.name;

        _isTranslating = true;
        _attachedAudio = AudioFileTranslation(
          fileName: fileName,
          filePath: filePath,
          duration: '0:32',
          sourceText: 'Analyzing speech on GPU server...',
          translatedText: 'Translating into ${_targetLang.name}...',
          sourceLang: _sourceLang.code,
          targetLang: _targetLang.code,
        );
        notifyListeners();

        final res = await _apiService.translateAudioFile(
          filePath: filePath,
          sourceLang: 'auto',
          targetLang: _targetLang.code,
          noiseReduction: _noiseReduction.toLowerCase(),
          isIndic: _isIndianLanguagesMode,
        );

        _attachedAudio = AudioFileTranslation(
          fileName: fileName,
          filePath: filePath,
          duration: '0:32',
          sourceText: res.sourceText.isNotEmpty ? res.sourceText : 'Audio communication processed',
          translatedText: res.translatedText,
          tacticalGist: res.tacticalGist,
          sourceLang: res.sourceLang,
          targetLang: res.targetLang,
          detectedLang: res.detectedLang.isNotEmpty ? res.detectedLang : (_isIndianLanguagesMode ? 'Hindi' : 'Chinese (Mandarin)'),
          latencyMs: res.latencyMs > 0 ? res.latencyMs : 38,
          confidence: res.confidence,
          tacticalMatches: res.tacticalMatches,
        );

        _currentResult = res;
        _isTranslating = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    // If file picker was cancelled or failed, load tactical sample audio
    loadSampleAudio();
    return true;
  }

  void loadSampleAudio() {
    _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');
    _attachedAudio = AudioFileTranslation(
      fileName: '1.mp3 (Operational Audio)',
      duration: '0:34',
      sourceText: '准备把装载机拉下来一下。怎么了？你说什么，装载机吗？是的，我去抬一下水。两个班组，两个桶，一个班组一桶，把水抬下来。',
      translatedText: 'Ready to bring the loader down. What did you say, the loader? Yes, I am going to fetch water. Two teams, two barrels to bring water down.',
      sourceLang: 'zh',
      targetLang: 'en',
      detectedLang: 'Chinese (Mandarin)',
      latencyMs: 35,
      confidence: 0.98,
      tacticalMatches: ['装载机 (Loader)', '水桶 (Two barrels)', '班组 (Two teams)'],
    );
    notifyListeners();
    retranslateAttachedAudio();
  }

  Future<void> retranslateAttachedAudio() async {
    if (_attachedAudio == null || _attachedAudio!.sourceText.isEmpty) return;
    _isTranslating = true;
    notifyListeners();

    final res = await _apiService.translateText(
      text: _attachedAudio!.sourceText,
      sourceLang: 'auto',
      targetLang: _targetLang.code,
      isIndic: _isIndianLanguagesMode,
    );

    _attachedAudio = _attachedAudio!.copyWith(
      translatedText: res.translatedText,
      targetLang: _targetLang.code,
      sourceLang: 'auto',
    );
    _isTranslating = false;
    notifyListeners();
  }

  void removeAttachedAudio() {
    _attachedAudio = null;
    notifyListeners();
  }

  Future<void> fetchTacticalGistForAudio() async {
    if (_attachedAudio == null) return;
    final textToSummarize = _attachedAudio!.translatedText.isNotEmpty
        ? _attachedAudio!.translatedText
        : _attachedAudio!.sourceText;
    if (textToSummarize.isEmpty) return;

    _isGeneratingGist = true;
    notifyListeners();

    try {
      final gist = await _apiService.generateTacticalGist(
        text: textToSummarize,
        sourceText: _attachedAudio!.sourceText,
        targetLang: _targetLang.code,
      );
      if (gist.isNotEmpty && _attachedAudio != null) {
        _attachedAudio = _attachedAudio!.copyWith(tacticalGist: gist);
      }
    } catch (_) {}

    _isGeneratingGist = false;
    notifyListeners();
  }

  Future<void> fetchTacticalGistForVideo() async {
    if (_attachedVideo == null) return;
    final textToSummarize = _attachedVideo!.translatedText.isNotEmpty
        ? _attachedVideo!.translatedText
        : _attachedVideo!.sourceText;
    if (textToSummarize.isEmpty) return;

    _isGeneratingGist = true;
    notifyListeners();

    try {
      final gist = await _apiService.generateTacticalGist(
        text: textToSummarize,
        sourceText: _attachedVideo!.sourceText,
        targetLang: _targetLang.code,
      );
      if (gist.isNotEmpty && _attachedVideo != null) {
        _attachedVideo = _attachedVideo!.copyWith(tacticalGist: gist);
      }
    } catch (_) {}

    _isGeneratingGist = false;
    notifyListeners();
  }

  // ==========================================
  // DOCUMENT / PDF TRANSLATION
  // ==========================================

  void selectDocument(int index) {
    if (index >= 0 && index < _attachedDocuments.length) {
      _selectedDocumentIndex = index;
      notifyListeners();
    }
  }

  void removeDocumentAt(int index) {
    if (index >= 0 && index < _attachedDocuments.length) {
      _attachedDocuments.removeAt(index);
      if (_selectedDocumentIndex >= _attachedDocuments.length) {
        _selectedDocumentIndex = _attachedDocuments.isNotEmpty ? _attachedDocuments.length - 1 : 0;
      }
      notifyListeners();
    }
  }

  void removeAttachedDocument() {
    _attachedDocuments.clear();
    _selectedDocumentIndex = 0;
    notifyListeners();
  }

  Future<bool> pickAndTranslateDocument({bool append = false}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx', 'doc', 'md'],
      );

      if (result.isNotEmpty) {
        if (!append) {
          _attachedDocuments.clear();
          _selectedDocumentIndex = 0;
        }

        _isTranslating = true;
        notifyListeners();

        for (final fileObj in result) {
          final filePath = fileObj.path;
          final fileName = fileObj.name;
          if (filePath == null) continue;

          String docContent = '';
          try {
            final file = File(filePath);
            if (filePath.endsWith('.txt') || filePath.endsWith('.md')) {
              docContent = await file.readAsString();
            }
          } catch (_) {}

          if (docContent.isEmpty) {
            docContent = 'Tactical Operating Procedure: Unit perimeter monitoring and radio frequency checks must be performed every 4 hours.\nEnsure all personnel maintain encrypted channels and log station identification.\nCheck power supply and antenna alignment before shift change.';
          }

          final lines = docContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
          final pages = <DocumentPage>[];

          for (int i = 0; i < (lines.length > 6 ? 6 : lines.length); i++) {
            final orig = lines[i];
            final trans = await _apiService.translateText(
              text: orig,
              sourceLang: _sourceLang.code,
              targetLang: _targetLang.code,
            );
            pages.add(DocumentPage(
              pageNumber: i + 1,
              originalText: orig,
              translatedText: trans.translatedText,
            ));
          }

          _attachedDocuments.add(DocumentTranslation(
            fileName: fileName,
            pageCount: pages.length,
            elapsedSeconds: 4 + _attachedDocuments.length * 2,
            pages: pages,
          ));
        }

        _selectedDocumentIndex = _attachedDocuments.isNotEmpty ? _attachedDocuments.length - 1 : 0;
        _isTranslating = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      _isTranslating = false;
      notifyListeners();
    }

    if (_attachedDocuments.isEmpty) {
      loadSampleDocument();
    }
    return true;
  }

  void loadSampleDocument() {
    _sourceLang = const Language(code: 'de', name: 'German', nativeName: 'Deutsch');
    _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');
    _attachedDocuments = [
      DocumentTranslation(
        fileName: 'service_manual_v4.pdf',
        pageCount: 2,
        elapsedSeconds: 6,
        pages: [
          DocumentPage(
            pageNumber: 1,
            originalText: 'Vor jeder Wartung ist die Hauptstromversorgung zu trennen.',
            translatedText: 'Disconnect the main power supply before every service operation.',
          ),
          DocumentPage(
            pageNumber: 2,
            originalText: 'Die Dichtungen sind alle 500 Betriebsstunden zu prüfen.',
            translatedText: 'Inspect the seals every 500 operating hours.',
          ),
        ],
      ),
      DocumentTranslation(
        fileName: 'tactical_brief_09.pdf',
        pageCount: 2,
        elapsedSeconds: 5,
        pages: [
          DocumentPage(
            pageNumber: 1,
            originalText: 'Alle Funkkanäle müssen auf die primäre Einsatzfrequenz eingestellt werden.',
            translatedText: 'All radio channels must be tuned to the primary operational frequency.',
          ),
          DocumentPage(
            pageNumber: 2,
            originalText: 'Die Patrouille meldet sich stündlich bei der Einsatzleitung.',
            translatedText: 'The patrol reports hourly to the operations command.',
          ),
        ],
      ),
    ];
    _selectedDocumentIndex = 0;
    notifyListeners();
  }

  Future<void> retranslateAttachedDocument() async {
    if (_attachedDocuments.isEmpty) return;
    _isTranslating = true;
    notifyListeners();

    final currentDoc = attachedDocument;
    if (currentDoc != null) {
      final updatedPages = <DocumentPage>[];
      for (final page in currentDoc.pages) {
        final res = await _apiService.translateText(
          text: page.originalText,
          sourceLang: _sourceLang.code,
          targetLang: _targetLang.code,
          isIndic: _isIndianLanguagesMode,
        );
        updatedPages.add(DocumentPage(
          pageNumber: page.pageNumber,
          originalText: page.originalText,
          translatedText: res.translatedText,
          confidence: page.confidence,
        ));
      }

      _attachedDocuments[_selectedDocumentIndex] = DocumentTranslation(
        fileName: currentDoc.fileName,
        pageCount: currentDoc.pageCount,
        elapsedSeconds: currentDoc.elapsedSeconds,
        pages: updatedPages,
      );
    }
    _isTranslating = false;
    notifyListeners();
  }

  // ==========================================
  // VIDEO MEDIA SUBTITLING
  // ==========================================

  Future<bool> pickAndTranslateVideo() async {
    try {
      PlatformFile? result;
      try {
        result = await FilePicker.pickFile(type: FileType.video);
      } catch (_) {}
      if (result == null) {
        try {
          result = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v', 'flv', 'ts'],
          );
        } catch (_) {}
      }
      if (result == null) {
        try {
          result = await FilePicker.pickFile(type: FileType.any);
        } catch (_) {}
      }

      if (result != null && result.path != null) {
        final filePath = result.path!;
        final fileName = result.name;

        _isTranslating = true;
        _attachedVideo = VideoMediaTranslation(
          videoTitle: fileName,
          filePath: filePath,
          duration: 'Processing...',
          progressPercent: 20,
          detectedLang: 'Detecting...',
          subtitles: [],
        );
        notifyListeners();

        final rawRes = await _apiService.translateVideoFile(
          filePath: filePath,
          targetLang: _targetLang.code,
          isIndic: _isIndianLanguagesMode,
        );

        String? streamUrl;
        if (rawRes['stream_url'] != null) {
          final rel = rawRes['stream_url'].toString();
          streamUrl = rel.startsWith('http') ? rel : '${_apiService.baseUrl}$rel';
        }

        final rawSubs = (rawRes['subtitles'] as List?) ?? [];
        final subtitles = rawSubs.map((s) {
          final m = s as Map<String, dynamic>;
          return VideoSubtitle(
            timestamp: m['timestamp']?.toString() ?? '00:00',
            originalText: m['original_text']?.toString() ?? '',
            translatedText: m['translated_text']?.toString() ?? '',
            start: (m['start'] as num?)?.toDouble(),
            end: (m['end'] as num?)?.toDouble(),
          );
        }).toList();

        _attachedVideo = VideoMediaTranslation(
          videoTitle: fileName,
          filePath: filePath,
          streamUrl: streamUrl,
          duration: rawSubs.isNotEmpty ? (rawSubs.last['timestamp']?.toString() ?? '1:15') : '1:15',
          progressPercent: 100,
          detectedLang: rawRes['detected_language']?.toString() ?? 'Auto-detected',
          sourceText: rawRes['source_text']?.toString() ?? '',
          translatedText: rawRes['translated_text']?.toString() ?? '',
          tacticalGist: rawRes['tactical_gist']?.toString() ?? '',
          latencyMs: (rawRes['latency_ms'] as num?)?.toInt() ?? 45,
          subtitles: subtitles,
        );

        _isTranslating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("pickAndTranslateVideo error: $e");
      _isTranslating = false;
      notifyListeners();
    }

    return false;
  }

  void loadSampleVideo() {
    _sourceLang = const Language(code: 'ja', name: 'Japanese', nativeName: '日本語');
    _targetLang = const Language(code: 'en', name: 'English', nativeName: 'English');
    _attachedVideo = VideoMediaTranslation(
      videoTitle: 'LINE_INSPECTION.MP4',
      duration: '1:17',
      progressPercent: 100,
      detectedLang: 'Japanese',
      sourceText: '部品の交換は月曜日までに終わります。その後、検査記録を送ってください。ここの担当者は...',
      translatedText: 'The parts replacement will be finished by Monday. After that, please send the inspection records. The person in charge here is...',
      latencyMs: 42,
      subtitles: [
        VideoSubtitle(
          timestamp: '0:48',
          start: 48.0,
          end: 62.0,
          originalText: '部品の交換は月曜日までに終わります。',
          translatedText: 'The parts replacement will be finished by Monday.',
        ),
        VideoSubtitle(
          timestamp: '1:02',
          start: 62.0,
          end: 75.0,
          originalText: 'その後、検査記録を送ってください。',
          translatedText: 'After that, please send the inspection records.',
        ),
        VideoSubtitle(
          timestamp: '1:15',
          start: 75.0,
          end: 77.0,
          originalText: 'ここの担当者は...',
          translatedText: 'The person in charge here is...',
        ),
      ],
    );
    notifyListeners();
  }

  Future<void> retranslateAttachedVideo() async {
    if (_attachedVideo == null) return;
    final filePath = _attachedVideo!.filePath;
    if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
      _isTranslating = true;
      notifyListeners();
      try {
        final rawRes = await _apiService.translateVideoFile(
          filePath: filePath,
          targetLang: _targetLang.code,
          isIndic: _isIndianLanguagesMode,
        );
        String? streamUrl = _attachedVideo?.streamUrl;
        String? playableFilePath = filePath;
        if (rawRes['stream_url'] != null) {
          final rel = rawRes['stream_url'].toString();
          streamUrl = rel.startsWith('http') ? rel : '${_apiService.baseUrl}$rel';
          try {
            final resp = await http.get(Uri.parse(streamUrl)).timeout(const Duration(seconds: 12));
            if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
              final videoId = rawRes['video_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
              final localFile = File('${Directory.systemTemp.path}/bhasha_transcoded_$videoId.mp4');
              await localFile.writeAsBytes(resp.bodyBytes);
              if (await localFile.exists()) {
                playableFilePath = localFile.path;
              }
            }
          } catch (e) {
            debugPrint('Local transcoded cache notice: $e');
          }
        }

        final rawSubs = (rawRes['subtitles'] as List?) ?? [];
        final subtitles = rawSubs.map((s) {
          final m = s as Map<String, dynamic>;
          return VideoSubtitle(
            timestamp: m['timestamp']?.toString() ?? '00:00',
            originalText: m['original_text']?.toString() ?? '',
            translatedText: m['translated_text']?.toString() ?? '',
            start: (m['start'] as num?)?.toDouble(),
            end: (m['end'] as num?)?.toDouble(),
          );
        }).toList();

        _attachedVideo = VideoMediaTranslation(
          videoTitle: _attachedVideo!.videoTitle,
          filePath: playableFilePath,
          streamUrl: streamUrl,
          duration: _attachedVideo!.duration,
          progressPercent: 100,
          detectedLang: rawRes['detected_language']?.toString() ?? _attachedVideo!.detectedLang,
          sourceText: rawRes['source_text']?.toString() ?? '',
          translatedText: rawRes['translated_text']?.toString() ?? '',
          latencyMs: (rawRes['latency_ms'] as num?)?.toInt() ?? 45,
          subtitles: subtitles,
        );
      } catch (_) {}
      _isTranslating = false;
      notifyListeners();
      return;
    }

    _isTranslating = true;
    notifyListeners();

    final updatedSubtitles = <VideoSubtitle>[];
    for (final sub in _attachedVideo!.subtitles) {
      final res = await _apiService.translateText(
        text: sub.originalText,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
      );
      updatedSubtitles.add(VideoSubtitle(
        timestamp: sub.timestamp,
        start: sub.start,
        end: sub.end,
        originalText: sub.originalText,
        translatedText: res.translatedText,
      ));
    }

    _attachedVideo = VideoMediaTranslation(
      videoTitle: _attachedVideo!.videoTitle,
      filePath: _attachedVideo!.filePath,
      duration: _attachedVideo!.duration,
      progressPercent: 100,
      detectedLang: _attachedVideo!.detectedLang,
      sourceText: _attachedVideo!.sourceText,
      translatedText: updatedSubtitles.map((s) => s.translatedText).join(' '),
      latencyMs: _attachedVideo!.latencyMs,
      subtitles: updatedSubtitles,
    );
    _isTranslating = false;
    notifyListeners();
  }

  void removeAttachedVideo() {
    _attachedVideo = null;
    notifyListeners();
  }

  void updateSpeechSettings({
    required String gender,
    required double speed,
  }) {
    _speechVoiceGender = gender;
    _speechPlaybackSpeed = speed;
    notifyListeners();
  }

  Future<void> speakText(String text, {String? langCode}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    if (_isPlayingTts && _currentSpeakingText == cleanText) {
      await stopSpeech();
      return;
    }

    try {
      await _ttsPlayer.stop();
    } catch (_) {}

    _isPlayingTts = true;
    _currentSpeakingText = cleanText;
    notifyListeners();

    final lang = (langCode != null && langCode.isNotEmpty) ? langCode : _targetLang.code;
    
    // 1. Try backend GPU TTS endpoint
    final serverTtsUrl = '${_apiService.baseUrl}/api/tts?text=${Uri.encodeComponent(cleanText)}&lang=$lang&gender=$_speechVoiceGender&speed=$_speechPlaybackSpeed';

    try {
      await _ttsPlayer.play(UrlSource(serverTtsUrl));
    } catch (e) {
      // 2. Fallback to Google Translate TTS
      try {
        final fallbackUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(cleanText)}&tl=$lang&client=tw-ob';
        await _ttsPlayer.play(UrlSource(fallbackUrl));
      } catch (e2) {
        _isPlayingTts = false;
        _currentSpeakingText = null;
        notifyListeners();
      }
    }
  }

  Future<void> stopSpeech() async {
    try {
      await _ttsPlayer.stop();
    } catch (_) {}
    _isPlayingTts = false;
    _currentSpeakingText = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _visualizerTimer?.cancel();
    _recordStreamSubscription?.cancel();
    _streamServiceSubscription?.cancel();
    _audioRecorder.dispose();
    _streamService.dispose();
    _ttsPlayer.dispose();
    super.dispose();
  }
}

