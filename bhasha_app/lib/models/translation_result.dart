class LiveSegment {
  final String sourceText;
  final String translatedText;
  final String detectedLang;

  LiveSegment({
    required this.sourceText,
    required this.translatedText,
    this.detectedLang = '',
  });

  factory LiveSegment.fromJson(Map<String, dynamic> json) {
    return LiveSegment(
      sourceText: json['source_text'] ?? '',
      translatedText: json['translated_text'] ?? '',
      detectedLang: json['detected_lang'] ?? '',
    );
  }
}

class TranslationResult {
  final String sourceText;
  final String translatedText;
  final String tacticalGist;
  final String sourceLang;
  final String targetLang;
  final String detectedLang;
  final int latencyMs;
  final double confidence;
  final List<String> tacticalMatches;
  final List<LiveSegment> segments;
  final DateTime timestamp;

  TranslationResult({
    required this.sourceText,
    required this.translatedText,
    this.tacticalGist = '',
    required this.sourceLang,
    required this.targetLang,
    this.detectedLang = '',
    this.latencyMs = 0,
    this.confidence = 0.98,
    this.tacticalMatches = const [],
    this.segments = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TranslationResult.fromJson(Map<String, dynamic> json, {String sourceLang = 'auto', String targetLang = 'en'}) {
    final rawSegments = json['segments'] as List<dynamic>?;
    final parsedSegments = rawSegments != null
        ? rawSegments.map((s) => LiveSegment.fromJson(s as Map<String, dynamic>)).toList()
        : <LiveSegment>[];

    return TranslationResult(
      sourceText: json['source_text'] ?? '',
      translatedText: json['translated_text'] ?? '',
      tacticalGist: json['tactical_gist'] ?? '',
      sourceLang: json['source_lang'] ?? sourceLang,
      targetLang: json['target_lang'] ?? targetLang,
      detectedLang: json['detected_language'] ?? json['detected_lang'] ?? '',
      latencyMs: json['latency_ms'] ?? 0,
      confidence: (json['confidence'] ?? 0.98).toDouble(),
      tacticalMatches: (json['tactical_matches'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      segments: parsedSegments,
      timestamp: DateTime.now(),
    );
  }
}

