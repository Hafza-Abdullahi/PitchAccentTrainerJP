import 'package:audioplayers/audioplayers.dart';

class AnkiAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String fileName) async {
    if (fileName.isEmpty) return;

    try {
      await _player.stop();

      // FIX FOR WEB:
      // 1. Remove any accidentally double-pasted brackets if they exist
      String cleanName = fileName.replaceAll('[sound:', '').replaceAll(']', '');

      // 2. URI Encode the filename.
      // Web browsers crash if filenames have spaces like "word 01.mp3".
      // This turns "word 01.mp3" into "word%2001.mp3" automatically.
      String encodedName = Uri.encodeComponent(cleanName);

      // 3. On Web, 'AssetSource' handles the 'assets/' prefix,
      // but we need to be explicit about the subfolder.
      await _player.play(AssetSource('audio/$cleanName'));

    } catch (e) {
      print("❌ Error playing audio: $e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}