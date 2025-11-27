class AnkiCardModel {
  final String word;
  final String wordReading;
  final String wordMeaning;
  final String sentence;
  final String wordAudio;

  const AnkiCardModel({
    required this.word,
    required this.wordReading,
    required this.wordMeaning,
    required this.sentence,
    required this.wordAudio,
  });

  ///Constructor to create card model
  /// matches the keys in the export anki script
  factory AnkiCardModel.fromJson(Map<String, dynamic> json) {
    return AnkiCardModel(
      word: json['word'] ?? '',
      wordReading: json['reading'] ?? '', // Maps 'reading' from JSON to 'wordReading'
      wordMeaning: json['meaning'] ?? '', // Maps 'meaning' from JSON to 'wordMeaning'
      sentence: json['sentence'] ?? '',
      wordAudio: json['audio'] ?? '',     // Maps 'audio' from JSON to 'wordAudio'
    );
  }
}