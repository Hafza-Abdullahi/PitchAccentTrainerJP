import 'package:audioplayers/audioplayers.dart';

class AnkiAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String fileName) async {
    if (fileName.isEmpty) return;

    try {
      await _player.stop();

      // Removed any accidentally double-pasted brackets if they exist
      String cleanName = fileName.replaceAll('[sound:', '').replaceAll(']', '');

      // URI Encode the filename.
      // Web browsers crash if filenames have spaces like "word 01.mp3".
      // - > This turns "word 01.mp3" into "word%2001.mp3" automatically.
      String encodedName = Uri.encodeComponent(cleanName);

      // 'AssetSource' handles the 'assets/' prefix,
      await _player.play(AssetSource('audio/$cleanName'));

    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}