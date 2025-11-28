import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart'; // needed for xfile

/// A controller class responsible for managing the communication between
/// the client application and the remote pitch analysis API.
class PitchAnalysisController {

  // The endpoint URL for the hosted Python Flask server.
  // Live url of render.
  static const String _apiUrl = "https://pitch-accent-api.onrender.com/";

  /**
   * Transmits audio data to the backend server for pitch contour analysis.
   *
   * This method handles the creation of a multipart HTTP request, determining
   * the appropriate method for file attachment based on the running platform
   * (Web vs. Mobile/Desktop).
   *
   * @param audioFile An [XFile] object representing a file selected via the file picker or drag-and-drop.
   *                  Required for Web environments where file paths are inaccessible.
   * @param audioPath A [String] representing the absolute file path on the device's storage.
   *                  Used primarily for recordings on mobile devices.
   * @return A [Future] that resolves to [Uint8List] containing the PNG image data if successful,
   *         or null if the request fails or an error occurs.
   */
  Future<Uint8List?> analyzeAudio({XFile? audioFile, String? audioPath}) async {
    try {
      final Uri uri = Uri.parse(_apiUrl);
      final http.MultipartRequest request = http.MultipartRequest('POST', uri);

      // 1. Attach users recording
      if (kIsWeb) {
        // In a Web environment, direct file system access is restricted.
        // The file must be read as a byte stream from the XFile object.
        if (audioFile != null) {
          final Uint8List bytes = await audioFile.readAsBytes();

          request.files.add(http.MultipartFile.fromBytes(
              'files',
              bytes,
              filename: 'user_audio.webm' // Web browsers typically record in WebM/Opus format.
          ));
        } else {
          // If no file object is provided on the web, operation cannot proceed.
          print("Error: No audio file object provided for Web upload.");
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

      // 2. Attach Native Speaker Audio (for future use))


      // 3. Execute the Request
      final http.StreamedResponse response = await request.send();

      // 4. Handle Response
      if (response.statusCode == 200) {
        // The server returns a raw PNG image. Convert the stream to bytes for display.
        return await response.stream.toBytes();
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