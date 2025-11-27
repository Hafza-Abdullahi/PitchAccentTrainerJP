import 'dart:convert'; // For jsonDecode
import 'package:flutter/services.dart'; // For rootBundle (to read assets)
import '../../features/authentication/models/anki_card_model.dart';

class AnkiRepository {

  /// Loads the "cards.json" file from the assets folder
  Future<List<AnkiCardModel>> loadLocalDeck() async {
    try {
      // 1. Read the text from the JSON file in assets
      final String response = await rootBundle.loadString('assets/json/cards.json');

      // 2. Convert the text string into a List of Maps
      final List<dynamic> data = jsonDecode(response);

      // 3. Map every item in the list to an AnkiCardModel
      return data.map((jsonItem) => AnkiCardModel.fromJson(jsonItem)).toList();

    } catch (e) {
      // If something goes wrong (e.g., file not found), print error and return empty list
      print("Error loading Anki JSON: $e");
      return [];
    }
  }
}