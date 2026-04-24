import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';

class AnkiCardModel {
  final String word;
  final String wordReading;
  final String wordMeaning;
  final String sentence;
  final String wordAudio;
  final String pitch;

  const AnkiCardModel({
    required this.word,
    required this.wordReading,
    required this.wordMeaning,
    required this.sentence,
    required this.wordAudio,
    required this.pitch,
  });

  factory AnkiCardModel.fromJson(Map<String, dynamic> json) {
    return AnkiCardModel(
      word: json['word'] ?? '',
      wordReading: json['reading'] ?? '',
      wordMeaning: json['meaning'] ?? '',
      sentence: json['sentence'] ?? '',
      wordAudio: json['audio'] ?? '',
      pitch: json['pitch'] ?? '',
    );
  }

}
