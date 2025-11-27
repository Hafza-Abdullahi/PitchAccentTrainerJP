import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// --- CONFIGURATION ---
const String deckName = "Kaishi 1.5k";
const int limit = 50; // How many cards to grab
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

  // Take only the first 50
  noteIds = noteIds.take(limit).toList();
  print("found ${noteIds.length} notes. Processing...");

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

  for (var note in notes) {
    var fields = note['fields'];

    // FIELD MAPS
    // ('Word', 'Sentence') to match Anki Field names exactly
    String word = fields['Word']['value'];
    String reading = fields['Word Reading']['value'];
    String meaning = fields['Word Meaning']['value'];
    String sentence = fields['Sentence']['value'];
    String rawAudio = fields['Word Audio']['value']; // audio files stored with each word already

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
    });

    count++;
    stdout.write("\rProcessed $count / ${noteIds.length}");
  }

  // Save JSON file
  final jsonFile = File('assets/json/cards.json');
  await jsonFile.writeAsString(jsonEncode(jsonOutput));

  print("\n\nSaved $count cards to assets/json/cards.json");
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
    // Retrieve media from Anki for the actual file content
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
  // Removes simple HTML tags like <div> or <b> if Anki has them
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}