import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart'; // needed for xfile

/// A controller class responsible for managing the communication between
/// the client application and the remote pitch analysis API.
class PitchAnalysisController {

  // The endpoint URL for the hosted Python Flask server.
  // Live url of render.
  static const String _apiUrl = "https://pitch-accent-api.onrender.com/process-audio";

  /**
   * Transmits audio data to the backend server for pitch contour analysis.
   *
   * This method handles the creation of a multipart HTTP request, determining
   * the appropriate method for file attachment based on the running platform
   * (Web vs. Mobile/Desktop).
   *
   * @param audioFile An [XFile] object representing a file selected via the file picker or drag-and-drop.
   * Required for Web environments where file paths are inaccessible.
   * @param audioPath A [String] representing the absolute file path on the device's storage.
   * Used primarily for recordings on mobile devices.
   * @return A [Future] that resolves to [Uint8List] containing the PNG image data if successful,
   * or null if the request fails or an error occurs.
   */

  /// ****************** Server wake up ping ******************
  Future<void> wakeUpServer() async {
    try {
      // ping the root "/" because it's lightweight
      final baseUrl = _apiUrl.replaceAll("/process-audio", "/"); // remove process audio to the get root url
      await http.get(Uri.parse(baseUrl));
      print("Server Woke Up!");
    } catch (e) {
      print("Server is sleeping or error: $e");
    }
  }

  Future<PitchAnalysisResult?> analyzeAudio({XFile? audioFile, String? audioPath, String? nativeAudioPath,}) async {
    try {
      final Uri uri = Uri.parse(_apiUrl);
      final http.MultipartRequest request = http.MultipartRequest('POST', uri);

      // 1. Attach users recording
      if (kIsWeb) {
        Uint8List? fileBytes;

        // Scenario A: User uploaded/dragged a file (XFile)
        if (audioFile != null) {
          fileBytes = await audioFile.readAsBytes();
        }
        // User recorded audio (Blob URL String)
        else if (audioPath != null) {
          // On Web, XFile can read a Blob URL (e.g. "blob:http://...")
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
        // In Mobile/Desktop environments, the file can be accessed directly via its path.
        if (audioPath != null) {
          request.files.add(await http.MultipartFile.fromPath(
              'files',
              audioPath
          ));
        } else if (audioFile != null) {
          // If an XFile was provided on mobile (e.g., via file picker), use its path.
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
        if (kIsWeb) {
          // Download the bytes of the native audio first because fromPath is unsupported on web
          final http.Response nativeRes = await http.get(Uri.parse(nativeAudioPath));
          request.files.add(http.MultipartFile.fromBytes(
              'native_audio',
              nativeRes.bodyBytes,
              filename: 'native_audio.mp3'
          ));
        } else {
          // Mobile/Desktop can use the path directly
          request.files.add(await http.MultipartFile.fromPath(
              'native_audio',
              nativeAudioPath
          ));
        }
      }

      // Execute the Request
      final http.StreamedResponse streamedResponse = await request.send(); // Changed name from 'response' to 'streamedResponse'

      // Convert StreamedResponse to Response
      final http.Response response = await http.Response.fromStream(streamedResponse);

      // 4. Handle Response
      if (response.statusCode == 200) {
        // Extract Headers (Note: Headers are typically lowercase in Dart http)
        String rawKanji = response.headers['x-transcription'] ?? "No Data";
        String rawRomaji = response.headers['x-transcription-romaji'] ?? "No Data";
        String rawAiScore = response.headers['x-ai-score'] ?? ""; //

        // Decode URL-encoded strings (e.g., "%E7%8C%AB" -> "猫")
        String decodedKanji = Uri.decodeComponent(rawKanji);
        String decodedRomaji = Uri.decodeComponent(rawRomaji);
        String decodedAiScore = Uri.decodeComponent(rawAiScore);

        // The server returns a raw PNG image. Convert the stream to bytes for display.
        return PitchAnalysisResult(
          imageBytes: response.bodyBytes,
          kanji: decodedKanji,
          romaji: decodedRomaji,
          aiScore: decodedAiScore,
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

/// A data model to encapsulate the response from the pitch analysis API.
/// This includes the visual graph and the linguistic transcription data.
class PitchAnalysisResult {
  final Uint8List imageBytes;
  final String kanji;
  final String romaji;
  final String aiScore;

  PitchAnalysisResult({
    required this.imageBytes,
    required this.kanji,
    required this.romaji,
    required this.aiScore,
  });
}