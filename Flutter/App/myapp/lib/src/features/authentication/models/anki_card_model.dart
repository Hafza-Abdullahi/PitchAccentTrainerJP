import 'package:cloud_firestore/cloud_firestore.dart';

class AnkiCardModel {
  final String? id;
  final String word;
  final String wordReading;
  final String wordMeaning;
  final String wordFurigana;
  final String sentence;
  final String sentenceMeaning;
  final String sentenceFurigana;
  final String pitchAccent;
  final int frequency;

  const AnkiCardModel({
    this.id,
    required this.word,
    required this.wordReading,
    required this.wordMeaning,
    required this.wordFurigana,
    required this.sentence,
    required this.sentenceMeaning,
    required this.sentenceFurigana,
    required this.pitchAccent,
    required this.frequency,
  });

  // Convert to Map for storing in Firebase
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'wordReading': wordReading,
      'wordMeaning': wordMeaning,
      'wordFurigana': wordFurigana,
      'sentence': sentence,
      'sentenceMeaning': sentenceMeaning,
      'sentenceFurigana': sentenceFurigana,
      'pitchAccent': pitchAccent,
      'frequency': frequency,
    };
  }

  // Create Model from Firebase Snapshot
  factory AnkiCardModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return AnkiCardModel(
      id: document.id,
      word: data['word'] ?? '',
      wordReading: data['wordReading'] ?? '',
      wordMeaning: data['wordMeaning'] ?? '',
      wordFurigana: data['wordFurigana'] ?? '',
      sentence: data['sentence'] ?? '',
      sentenceMeaning: data['sentenceMeaning'] ?? '',
      sentenceFurigana: data['sentenceFurigana'] ?? '',
      pitchAccent: data['pitchAccent'] ?? '',
      frequency: data['frequency'] ?? 0,
    );
  }
}