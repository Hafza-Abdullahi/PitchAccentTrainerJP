import 'dart:io';
import 'dart:typed_data'; // needed for Uint8List

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// --- PACKAGES ---
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../common_widgets/card/word_card.dart';
import '../../../../repository/anki_repository/anki_repository.dart';
import '../../../../utils/anki_audio_player.dart';
import '../../controllers/PitchAnalysisController.dart';
import '../../models/anki_card_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /******************** VARIABLES *******************/
  final AnkiRepository _repository = AnkiRepository();
  final AnkiAudioPlayer _nativeAudioPlayer = AnkiAudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _userAudioPlayer = AudioPlayer();

  int _currentIndex = 0;
  late Future<List<AnkiCardModel>> _cardsFuture;

  // -- Recorder State --
  bool _isRecording = false;
  String? _userRecordingPath;

  // -- Drag & Drop State --
  bool _isHoveringDropZone = false;
  XFile? _droppedFile;

  // init audio recorder
  final PitchAnalysisController _pitchController = PitchAnalysisController();

  // Variable to store the image result for later
  Uint8List? _graphImage;
  bool _isAnalyzing = false; // To show a loading spinner while waiting for the server



  /******************** CYCLE METHODS *******************/
  @override
  void initState() {
    super.initState();
    _cardsFuture = _repository.loadLocalDeck();
  }

  @override
  void dispose() {
    _nativeAudioPlayer.dispose();
    _userAudioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  /******************** FILE PICKER LOGIC (CLICK) *******************/
  Future<void> _pickFile() async {
    try {
      // Open the file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        XFile pickedFile;

        if (kIsWeb) {
          // Web Logic: strictly use bytes
          // check if bytes are available to avoid the crash
          if (file.bytes != null) {
            pickedFile = XFile.fromData(file.bytes!, name: file.name);
          } else {
            print(
                "Error: The browser didn't give us the file data! (Bytes are null)");
            return;
          }
        } else {
          // Mobile/Desktop Logic: strictly use path
          if (file.path != null) {
            pickedFile = XFile(file.path!);
          } else {
            print("Error: File path is missing.");
            return;
          }
        }

        // update the UI
        setState(() {
          _droppedFile = pickedFile;
          _userRecordingPath = null;
        });
        print("File picked successfully: ${_droppedFile!.name}");
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  /******************** RECORDER LOGIC *******************/
  Future<void> _startRecording() async {
    setState(() => _droppedFile = null); // Clear file if we start recording

    try {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder
              .start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
        } else {
          final dir = await getTemporaryDirectory();
          String path = '${dir.path}/user_practice.m4a';
          await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.aacLc),
              path: path);
        }

        setState(() {
          _isRecording = true;
          _userRecordingPath = null;
        });
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _userRecordingPath = path;
      });
    } catch (e) {
      print("Error stopping record: $e");
    }
  }

  /******************** PLAYBACK LOGIC *******************/
  Future<void> _playUserContent() async {
    try {
      if (_droppedFile != null) {
        // Play the dropped/picked file
        if (kIsWeb) {
          await _userAudioPlayer.play(UrlSource(_droppedFile!.path));
        } else {
          await _userAudioPlayer.play(DeviceFileSource(_droppedFile!.path));
        }
      } else if (_userRecordingPath != null) {
        // Play the mic recording
        Source source = (kIsWeb)
            ? UrlSource(_userRecordingPath!)
            : DeviceFileSource(_userRecordingPath!);
        await _userAudioPlayer.play(source);
      }
    } catch (e) {
      print("Error playing user audio: $e");
    }
  }

  /******************** ANALYSIS LOGIC *******************/

  // Sends the current audio to the server and updates the UI with the result
  Future<void> _runAnalysis() async {
    // 1. Validation: Ensure we actually have audio to send
    if (_droppedFile == null && _userRecordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please record or upload audio first."))
      );
      return;
    }

    setState(() {
      _isAnalyzing = true; // Start loading spinner
      _graphImage = null;  // Clear previous graph
    });

    // 2. Call the Controller
    final Uint8List? result = await _pitchController.analyzeAudio(
        audioFile: _droppedFile,
        audioPath: _userRecordingPath
    );

    // 3. Update UI
    setState(() {
      _isAnalyzing = false; // Stop loading
      if (result != null) {
        _graphImage = result; // Display the graph
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Analysis failed. Please Check server connection."))
        );
      }
    });
  }

  /******************** GRAPH LOGIC *******************/
  Future<void> _generateGraph() async {
    // Call the controller to generate the graph
    // pass _droppedFile (for drag/drop/web) AND _userRecordingPath (for mobile mic)
    final result = await _pitchController.analyzeAudio(
        audioFile: _droppedFile, audioPath: _userRecordingPath);

    if (result != null) {
      setState(() {
        _graphImage = result; // Save the image data to display
      });
    }
  }

  /******************** CARD LOGIC *******************/
  void _nextCard(int totalCards) {
    setState(() {
      _userRecordingPath = null;
      _droppedFile = null;
      _isRecording = false;
      _graphImage = null; // Clear the graph for the new word.

      if (_currentIndex < totalCards - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  /******************** UI BUILD *******************/
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: tBackgroundColor,
        appBar: AppBar(
          title: const Text("My Anki Deck"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FutureBuilder<List<AnkiCardModel>>(
              future: _cardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No cards found."));
                }

                final cards = snapshot.data!;
                final currentCard = cards[_currentIndex];

                return Padding(
                  padding: const EdgeInsets.all(tDefaultSize),
                  child: Column(
                    children: [
                      Text("Card ${_currentIndex + 1} of ${cards.length}",
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),

                      // --- MAIN CARD ---
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                WordCard(
                                  card: currentCard,
                                  onPlayAudio: () =>
                                      _nativeAudioPlayer.play(
                                          currentCard.wordAudio),
                                ),

                                const SizedBox(height: 20),

                                /*----------------- AUDIO CONTROLS -----------------*/
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // MIC BUTTON
                                    GestureDetector(
                                      onLongPress: _startRecording,
                                      onLongPressUp: _stopRecording,
                                      onTap: () =>
                                      _isRecording
                                          ? _stopRecording()
                                          : _startRecording(),
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: _isRecording
                                              ? Colors.red
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.grey
                                                .withOpacity(0.3),
                                                blurRadius: 10)
                                          ],
                                        ),
                                        child: Icon(
                                            _isRecording ? Icons.stop : Icons
                                                .mic, color: _isRecording
                                            ? Colors.white
                                            : tPrimaryColor, size: 30),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // DROP ZONE / UPLOAD BUTTON
                                    DropTarget(
                                      onDragDone: (details) {
                                        if (details.files.isNotEmpty) {
                                          setState(() {
                                            _droppedFile =
                                                details.files.first;
                                            _userRecordingPath = null;
                                            _graphImage = null;
                                          });
                                        }
                                      },
                                      onDragEntered: (details) =>
                                          setState(() =>
                                          _isHoveringDropZone = true),
                                      onDragExited: (details) =>
                                          setState(() =>
                                          _isHoveringDropZone = false),

                                      // CLICKABLE AREA
                                      child: InkWell(
                                        onTap: _pickFile,
                                        borderRadius: BorderRadius.circular(
                                            50),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: _isHoveringDropZone
                                                ? Colors.blue.shade100
                                                : (_droppedFile != null
                                                ? Colors.green.shade100
                                                : Colors.white),
                                            shape: BoxShape.circle,
                                            border: _isHoveringDropZone
                                                ? Border.all(
                                                color: Colors.blue, width: 2)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(color: Colors.grey
                                                  .withOpacity(0.3),
                                                  blurRadius: 10)
                                            ],
                                          ),
                                          // generic upload icon
                                          child: Icon(
                                            _droppedFile != null
                                                ? Icons.check
                                                : Icons.upload,
                                            color: _droppedFile != null
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // 3. PLAYBACK BUTTON
                                    if ((_userRecordingPath != null ||
                                        _droppedFile != null) &&
                                        !_isRecording)
                                      ElevatedButton.icon(
                                        onPressed: _playUserContent,
                                        icon: const Icon(Icons.play_arrow),
                                        label: Text(_droppedFile != null
                                            ? "Play File"
                                            : "Play Rec"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),

                                // Instructions
                                if (_isRecording)
                                  const Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text("Recording...",
                                          style: TextStyle(
                                              color: Colors.red)))
                                else
                                  if (_droppedFile != null)
                                    Padding(padding: const EdgeInsets.only(
                                        top: 10),
                                        child: Text(
                                            "Ready: ${_droppedFile!.name}",
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12)))
                                  else
                                    const Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text("Tap Mic or Upload Audio",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12))),

                                const SizedBox(height: 20),

                                /*----------------- ANALYZE SECTION -----------------*/
                                // Only show if audio is present and not recording
                                if ((_userRecordingPath != null || _droppedFile != null) && !_isRecording)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isAnalyzing ? null : _generateGraph,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: _isAnalyzing
                                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text("Analyze Pitch"),
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                /*----------------- RESULT GRAPH -----------------*/
                                if (_graphImage != null)
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        _graphImage!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: tDefaultSize),

                      // --- NEXT BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _nextCard(cards.length),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tPrimaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Next Word", style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
