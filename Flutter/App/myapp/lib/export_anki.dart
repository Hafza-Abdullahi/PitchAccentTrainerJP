import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// --- CONFIGURATION ---
const String deckName = "Japanese Core 6000 Vocab"; // Name of the deck to grab
const int limit = 150; // How many cards to grab
// ---------------------

Future<void> main() async {
  print("Connecting to Anki...");

  // Get Note IDs
  final idsResponse = await _ankiRequest('findNotes', {
    'query': '"deck:$deckName"'
  });

  // deck is empty
  List<dynamic> noteIds = idsResponse['result'];
  if (noteIds.isEmpty) {
    print("No notes found! Check the deck name exactly.");
    return;
  }

  // Take only the first 150
  noteIds = noteIds.take(limit).toList();
  print("Found ${noteIds.length} notes. Processing...");

  // Get Note Details
  final notesResponse = await _ankiRequest('notesInfo', {
    'notes': noteIds
  });

  List<dynamic> notes = notesResponse['result'];
  List<Map<String, dynamic>> jsonOutput = [];

  // Create directories
  Directory('assets/audio').createSync(recursive: true);
  Directory('assets/json').createSync(recursive: true);

  int count = 0;
  int skipped = 0; // Keep track of how many cards were broken

  for (var note in notes) {
    var fields = note['fields'];

    // FIELD MAPS (Using ?. fallback just in case a field key completely doesn't exist)
    String word = fields['Word']?['value'] ?? '';
    String reading = fields['Transliteration']?['value'] ?? '';
    String meaning = fields['Meaning']?['value'] ?? '';
    String sentence = fields['Example Sentence']?['value'] ?? '';
    String rawAudio = fields['Word Audio']?['value'] ?? '';
    String pitch = fields['Pitch Accent']?['value'] ?? '';

    // THE FILTER
    // If ANY of these strings are completely empty, or say "No data available", skip this card!
    if (word.trim().isEmpty ||
        reading.trim().isEmpty ||
        meaning.trim().isEmpty ||
        sentence.trim().isEmpty ||
        rawAudio.trim().isEmpty ||
        pitch.trim().isEmpty ||
        pitch.contains('No data available')) { // PLACEHOLDER CARDS

      skipped++;
      continue; // Jumps to the next card in the loop
    }

    // Clean Audio Filename
    String audioFilename = rawAudio.replaceAll('[sound:', '').replaceAll(']', '');

    // Retrieve Audio Content (Base64) and Save to File
    if (audioFilename.isNotEmpty) {
      await _saveAudioFile(audioFilename);
    }

    // Add to list
    jsonOutput.add({
      'word': _cleanHtml(word),
      'reading': _cleanHtml(reading),
      'meaning': _cleanHtml(meaning),
      'sentence': _cleanHtml(sentence),
      'audio': audioFilename,
      'pitch': pitch, // Passed raw, keeps any OJAD formatting
    });

    count++;
    stdout.write("\rProcessed: $count | Skipped: $skipped / ${noteIds.length}");
  }

  // Save JSON file
  final jsonFile = File('assets/json/cards.json');
  await jsonFile.writeAsString(jsonEncode(jsonOutput));

  print("\n\nSaved $count perfect cards to assets/json/cards.json");
  if (skipped > 0) {
    print("Threw away $skipped cards because they were missing data.");
  }
  print("Audio files saved to assets/audio/");
}

// --- HELPER FUNCTIONS FOR ANKI CONNECT---
Future<Map<String, dynamic>> _ankiRequest(String action, Map<String, dynamic> params) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8765'),
    body: jsonEncode({'action': action, 'version': 6, 'params': params}),
  );
  return jsonDecode(response.body);
}

Future<void> _saveAudioFile(String filename) async {
  try {
    final response = await _ankiRequest('retrieveMediaFile', {'filename': filename});
    final String? base64Data = response['result'];

    if (base64Data != null && base64Data != false) {
      final bytes = base64Decode(base64Data);
      final file = File('assets/audio/$filename');
      await file.writeAsBytes(bytes);
    }
  } catch (e) {
    print("Error saving audio $filename: $e");
  }
}

String _cleanHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}