class AudioFileTranslation {
  final String fileName;
  final String? filePath;
  final String duration;
  final String sourceText;
  final String translatedText;
  final String tacticalGist;
  final String sourceLang;
  final String targetLang;
  final String detectedLang;
  final int latencyMs;
  final double confidence;
  final List<String> tacticalMatches;

  AudioFileTranslation({
    required this.fileName,
    this.filePath,
    required this.duration,
    required this.sourceText,
    required this.translatedText,
    this.tacticalGist = '',
    required this.sourceLang,
    required this.targetLang,
    this.detectedLang = 'Auto',
    this.latencyMs = 45,
    this.confidence = 0.98,
    this.tacticalMatches = const [],
  });

  AudioFileTranslation copyWith({
    String? fileName,
    String? filePath,
    String? duration,
    String? sourceText,
    String? translatedText,
    String? tacticalGist,
    String? sourceLang,
    String? targetLang,
    String? detectedLang,
    int? latencyMs,
    double? confidence,
    List<String>? tacticalMatches,
  }) {
    return AudioFileTranslation(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      tacticalGist: tacticalGist ?? this.tacticalGist,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      detectedLang: detectedLang ?? this.detectedLang,
      latencyMs: latencyMs ?? this.latencyMs,
      confidence: confidence ?? this.confidence,
      tacticalMatches: tacticalMatches ?? this.tacticalMatches,
    );
  }
}
