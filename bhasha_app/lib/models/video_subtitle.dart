class VideoSubtitle {
  final String timestamp;
  final String originalText;
  final String translatedText;
  final double? start;
  final double? end;

  VideoSubtitle({
    required this.timestamp,
    required this.originalText,
    required this.translatedText,
    this.start,
    this.end,
  });

  VideoSubtitle copyWith({
    String? timestamp,
    String? originalText,
    String? translatedText,
    double? start,
    double? end,
  }) {
    return VideoSubtitle(
      timestamp: timestamp ?? this.timestamp,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class VideoMediaTranslation {
  final String videoTitle;
  final String? filePath;
  final String? streamUrl;
  final String duration;
  final int progressPercent;
  final String detectedLang;
  final String sourceText;
  final String translatedText;
  final String tacticalGist;
  final int latencyMs;
  final List<VideoSubtitle> subtitles;

  VideoMediaTranslation({
    required this.videoTitle,
    this.filePath,
    this.streamUrl,
    required this.duration,
    this.progressPercent = 100,
    this.detectedLang = 'Chinese (Mandarin)',
    this.sourceText = '',
    this.translatedText = '',
    this.tacticalGist = '',
    this.latencyMs = 45,
    required this.subtitles,
  });

  VideoMediaTranslation copyWith({
    String? videoTitle,
    String? filePath,
    String? streamUrl,
    String? duration,
    int? progressPercent,
    String? detectedLang,
    String? sourceText,
    String? translatedText,
    String? tacticalGist,
    int? latencyMs,
    List<VideoSubtitle>? subtitles,
  }) {
    return VideoMediaTranslation(
      videoTitle: videoTitle ?? this.videoTitle,
      filePath: filePath ?? this.filePath,
      streamUrl: streamUrl ?? this.streamUrl,
      duration: duration ?? this.duration,
      progressPercent: progressPercent ?? this.progressPercent,
      detectedLang: detectedLang ?? this.detectedLang,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      tacticalGist: tacticalGist ?? this.tacticalGist,
      latencyMs: latencyMs ?? this.latencyMs,
      subtitles: subtitles ?? this.subtitles,
    );
  }
}
