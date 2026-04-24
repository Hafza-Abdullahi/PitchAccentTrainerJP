import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart'; // needed for xfile
import 'package:flutter/services.dart' show rootBundle; // needed to grab native audio

/// A controller class responsible for managing the communication between
/// the client application and the remote pitch analysis API.
class PitchAnalysisController {

  // The endpoint URL for the hosted Python Flask server.
  // Live url of render.
  static const String _apiUrl = "https://pitch-accent-api.onrender.com/process-audio";

  /// ****************** Server wake up ping ******************
  Future<void> wakeUpServer() async {
    try {
      final baseUrl = _apiUrl.replaceAll("/process-audio", "/");
      await http.get(Uri.parse(baseUrl));
      print("Server Woke Up!");
    } catch (e) {
      print("Server is sleeping or error: $e");
    }
  }

  Future<PitchAnalysisResult?> analyzeAudio({XFile? audioFile, String? audioPath, String? nativeAudioPath, required String targetRomaji,}) async {
    try {
      final Uri uri = Uri.parse(_apiUrl);
      final http.MultipartRequest request = http.MultipartRequest('POST', uri);

      // 🔍 DEBUG (safe to keep)
      print("Running on web: $kIsWeb");
      print("audioPath: $audioPath");
      print("audioFile: $audioFile");
      print("nativeAudioPath: $nativeAudioPath");
      print("targetRomaji: $targetRomaji");

      // romaji for comparision
      request.fields['target_romaji'] = targetRomaji;

      // 1. Attach users recording
      if (kIsWeb) {
        Uint8List? fileBytes;

        // Scenario A: User uploaded/dragged a file (XFile)
        if (audioFile != null) {
          fileBytes = await audioFile.readAsBytes();
        }
        // User recorded audio (Blob URL String)
        else if (audioPath != null) {
          final recordedFile = XFile(audioPath);
          fileBytes = await recordedFile.readAsBytes();
        }

        // Proceed if we successfully got bytes from A or B
        if (fileBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
              'files',
              fileBytes,
              filename: 'user_audio.webm'
          ));
        } else {
          print("Error: No audio file or recording found for Web upload.");
          return null;
        }

      } else {
        // EXTRA SAFETY: ensure web NEVER reaches here
        if (kIsWeb) {
          print("ERROR: Web tried to access fromPath()");
          return null;
        }

        // In Mobile/Desktop environments, the file can be accessed directly via its path.
        if (audioPath != null) {
          request.files.add(await http.MultipartFile.fromPath(
              'files',
              audioPath
          ));
        } else if (audioFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
              'files',
              audioFile.path
          ));
        } else {
          print("Error: No audio path provided for mobile upload.");
          return null;
        }
      }

      // Attach Native Speaker Audio (for future use))
      if (nativeAudioPath != null && nativeAudioPath.isNotEmpty) {
        try {
          // Read the asset directly from memory into raw bytes (Works on all platforms)
          final ByteData nativeData = await rootBundle.load(nativeAudioPath);
          final Uint8List nativeBytes = nativeData.buffer.asUint8List();

          request.files.add(http.MultipartFile.fromBytes(
              'native_audio',
              nativeBytes,
              filename: 'native_audio.mp3' // Dummy filename so the Flask server accepts it
          ));
        } catch (e) {
          print("Error loading native audio asset: $e");
        }
      }

      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        String rawKanji = response.headers['x-transcription'] ?? "No Data";
        String rawRomaji = response.headers['x-transcription-romaji'] ?? "No Data";
        String rawCombinedScore = response.headers['x-combined-score'] ?? "";
        String rawAiScore = response.headers['x-ai-score'] ?? "";
        String rawDtwScore = response.headers['x-dtw-score'] ?? "";


        String decodedKanji = Uri.decodeComponent(rawKanji);
        String decodedRomaji = Uri.decodeComponent(rawRomaji);
        String decodedAiScore = Uri.decodeComponent(rawAiScore);
        String decodedCombinedScore = Uri.decodeComponent(rawCombinedScore);
        String decodedDtwScore = Uri.decodeComponent(rawDtwScore);

        return PitchAnalysisResult(
          imageBytes: response.bodyBytes,
          kanji: decodedKanji,
          romaji: decodedRomaji,
          aiScore: decodedAiScore,
          dtwScore: decodedDtwScore,
          combinedScore: decodedCombinedScore,
        );
      } else {
        print("Server Error: HTTP status code ${response.statusCode}");
        return null;
      }

    } catch (e) {
      print("Connection Exception during pitch analysis: $e");
      return null;
    }
  }
}

class PitchAnalysisResult {
  final Uint8List imageBytes;
  final String kanji;
  final String romaji;
  final String aiScore;
  final String dtwScore;
  final String combinedScore;


  PitchAnalysisResult({
    required this.imageBytes,
    required this.kanji,
    required this.romaji,
    required this.aiScore,
    required this.dtwScore,
    required this.combinedScore,
  });
}