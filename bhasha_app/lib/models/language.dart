class Language {
  final String code;
  final String name;
  final String nativeName;
  final bool isRecent;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRecent = false,
  });

  static const List<Language> recentLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English', isRecent: true),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文 (Mandarin)', isRecent: true),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', isRecent: true),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский', isRecent: true),
  ];

  static const List<Language> indicRecentLanguages = [
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', isRecent: true),
    Language(code: 'en', name: 'English', nativeName: 'English', isRecent: true),
    Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', isRecent: true),
    Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', isRecent: true),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', isRecent: true),
  ];

  /// 22 Official Scheduled Indian Languages + English supported by IndicConformer & IndicTrans2
  static const List<Language> indicLanguages = [
    Language(code: 'as', name: 'Assamese', nativeName: 'অসমীয়া'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    Language(code: 'brx', name: 'Bodo', nativeName: 'बड़ो'),
    Language(code: 'doi', name: 'Dogri', nativeName: 'डोगरी'),
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    Language(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    Language(code: 'ks', name: 'Kashmiri', nativeName: 'कॉशुर / کٲشُر'),
    Language(code: 'gom', name: 'Konkani', nativeName: 'कोंकणी'),
    Language(code: 'mai', name: 'Maithili', nativeName: 'मैथिली'),
    Language(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
    Language(code: 'mni', name: 'Manipuri', nativeName: 'মৈতৈলোন্'),
    Language(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    Language(code: 'ne', name: 'Nepali', nativeName: 'नेपाली'),
    Language(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
    Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    Language(code: 'sa', name: 'Sanskrit', nativeName: 'संस्कृतम्'),
    Language(code: 'sat', name: 'Santali', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ'),
    Language(code: 'sd', name: 'Sindhi', nativeName: 'سنڌي / सिन्धी'),
    Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
    Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
  ];

  static const List<Language> allLanguages = [
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文 (Mandarin)'),
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'fr', name: 'French', nativeName: 'Français'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
    Language(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    Language(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
    Language(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
    Language(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
    Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
  ];

  static List<Language> getLanguages({bool isIndic = false}) {
    return isIndic ? indicLanguages : allLanguages;
  }

  static List<Language> getRecentLanguages({bool isIndic = false}) {
    return isIndic ? indicRecentLanguages : recentLanguages;
  }

  static Language fromCode(String code) {
    final searchList = [...indicLanguages, ...allLanguages];
    return searchList.firstWhere(
      (l) => l.code == code,
      orElse: () => const Language(code: 'en', name: 'English', nativeName: 'English'),
    );
  }
}
