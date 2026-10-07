class DocumentPage {
  final int pageNumber;
  final String originalText;
  final String translatedText;
  final double confidence;

  DocumentPage({
    required this.pageNumber,
    required this.originalText,
    required this.translatedText,
    this.confidence = 0.99,
  });
}

class DocumentTranslation {
  final String fileName;
  final int pageCount;
  final int elapsedSeconds;
  final List<DocumentPage> pages;

  DocumentTranslation({
    required this.fileName,
    required this.pageCount,
    required this.elapsedSeconds,
    required this.pages,
  });
}
