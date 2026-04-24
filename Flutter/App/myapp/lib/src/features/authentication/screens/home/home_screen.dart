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
import 'package:file_picker/file_picker.dart' as fp;

import '../../../../common_widgets/card/word_card.dart';
import '../../../../repository/anki_repository/anki_repository.dart';
import '../../../../utils/anki_audio_player.dart';
import '../../controllers/PitchAnalysisController.dart';
import '../../models/anki_card_model.dart';
import 'package:flutter/services.dart'; // Needed for rootBundle

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

  // Init analysis controller
  final PitchAnalysisController _pitchController = PitchAnalysisController();

  int _currentIndex = 0;
  late Future<List<AnkiCardModel>> _cardsFuture;

  // -- Recorder State --
  bool _isRecording = false;
  String? _userRecordingPath;

  // -- Drag & Drop State --
  bool _isHoveringDropZone = false;
  XFile? _droppedFile;

  // -- Analysis Result State --
  Uint8List? _graphImage;
  String _detectedKanji = "";
  String _detectedRomaji = "";
  String _aiScore = "";
  String _combinedScore = "";
  String _dtwScore = "";
  bool _isAnalyzing = false;

  /******************** CYCLE METHODS *******************/
  @override
  void initState() {
    super.initState();
    _cardsFuture = _repository.loadLocalDeck();

    // ping server to wake it up (Render free version shuts down server after inactivity,
    // first request to anyzle will be delayed by 50secs. so waking it up now while everything is loading is better)
    _pitchController.wakeUpServer();
  }

  @override
  void dispose() {
    _nativeAudioPlayer.dispose();
    _userAudioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }


  /******************** FILE PICKER LOGIC *******************/
  Future<void> _pickFile() async {
    try {
      // Add .platform back here
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        fp.PlatformFile file = result.files.first;
        XFile pickedFile;

        if (kIsWeb) {
          if (file.bytes != null) {
            pickedFile = XFile.fromData(file.bytes!, name: file.name);
          } else {
            print("Error: The browser didn't give us the file data!");
            return;
          }
        } else {
          if (file.path != null) {
            pickedFile = XFile(file.path!);
          } else {
            print("Error: File path is missing.");
            return;
          }
        }

        setState(() {
          _droppedFile = pickedFile;
          _userRecordingPath = null;
          // Reset analysis results
          _graphImage = null;
          _detectedKanji = "";
          _detectedRomaji = "";
          _aiScore = "";
          _combinedScore = "";
          _dtwScore = "";
        });
        print("File picked successfully: ${_droppedFile!.name}");
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  /******************** RECORDER LOGIC *******************/
  Future<void> _startRecording() async {
    setState(() {
      _droppedFile = null;
      _graphImage = null;
      _detectedKanji = "";
      _detectedRomaji = "";
      _aiScore = "";
      _combinedScore = "";
      _dtwScore = "";
    });

    try {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.opus),
              path: ''
          );
        } else {
          final dir = await getTemporaryDirectory();
          String path = '${dir.path}/user_practice.m4a';
          await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.aacLc),
              path: path
          );
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
        if (kIsWeb) {
          await _userAudioPlayer.play(UrlSource(_droppedFile!.path));
        } else {
          await _userAudioPlayer.play(DeviceFileSource(_droppedFile!.path));
        }
      } else if (_userRecordingPath != null) {
        Source source = (kIsWeb)
            ? UrlSource(_userRecordingPath!)
            : DeviceFileSource(_userRecordingPath!);
        await _userAudioPlayer.play(source);
      }
    } catch (e) {
      print("Error playing user audio: $e");
    }
  }

  /******************** GRAPH & TEXT LOGIC *******************/
  Future<void> _generateGraph(AnkiCardModel currentCard) async {
    // Fixed file name to avoid name errors
    String fixedFileName = currentCard.wordAudio.replaceAll('\\', '＼');
    print("FILENAME: $fixedFileName");

    // Validation
    if (_droppedFile == null && _userRecordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please record or upload audio first."))
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _graphImage = null; // Clear previous
      _detectedKanji = "";
      _detectedRomaji = "";
      _aiScore = "";
      _combinedScore = "";
      _dtwScore = "";
    });

    // Call the controller (Returns PitchAnalysisResult object)
    final PitchAnalysisResult? result = await _pitchController.analyzeAudio(
      audioFile: _droppedFile,
      audioPath: _userRecordingPath,
        nativeAudioPath: 'assets/audio/$fixedFileName'
    );
    print("You scored: ${result?.aiScore}");

    setState(() {
      _isAnalyzing = false;

      if (result != null) {
        // Unpack the data from the Result Object
        _graphImage = result.imageBytes;
        _detectedKanji = result.kanji;
        _detectedRomaji = result.romaji;
        _aiScore = result.aiScore;
        _combinedScore = result.combinedScore;
        _dtwScore = result.dtwScore;

        print("DETECTED WORDS $_detectedKanji $_detectedRomaji" );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Analysis failed. Check server."))
        );
      }
    });
  }

  /******************** CARD LOGIC *******************/
  void _nextCard(int totalCards) {
    setState(() {
      _userRecordingPath = null;
      _droppedFile = null;
      _isRecording = false;
      // Clear analysis
      _graphImage = null;
      _detectedKanji = "";
      _detectedRomaji = "";
      _aiScore = "";
      _combinedScore = "";
      _dtwScore = "";

      if (_currentIndex < totalCards - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  /******************** DEMO LOGIC *******************/
  Future<void> _loadDemoFile(String fileName) async {
    try {
      // Load bytes from the asset bundle
      final byteData = await rootBundle.load('assets/demo_audio/$fileName');
      final bytes = byteData.buffer.asUint8List();

      // Create an XFile (Fake upload)
      final demoFile = XFile.fromData(
        bytes,
        name: fileName,
        length: bytes.length,
      );

      // Update State
      setState(() {
        _droppedFile = demoFile;
        _userRecordingPath = null;
        _graphImage = null; // Clear old graph
        _detectedKanji = "";
        _detectedRomaji = "";
        _aiScore = "";
        _combinedScore = "";
        _dtwScore = "";
      });

      print("Demo file loaded: $fileName");

      // Optional: Auto-analyze immediately?
      // _generateGraph();

    } catch (e) {
      print("Error loading demo asset: $e");
    }
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

                      // --- MAIN CARD AREA ---
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                WordCard(
                                  card: currentCard,
                                  onPlayAudio: () =>
                                      _nativeAudioPlayer.play(currentCard.wordAudio),
                                ),

                                const SizedBox(height: 20),

                                /*----------------- AUDIO CONTROLS -----------------*/
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Mic Button
                                    GestureDetector(
                                      onLongPress: _startRecording,
                                      onLongPressUp: _stopRecording,
                                      onTap: () => _isRecording ? _stopRecording() : _startRecording(),
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: _isRecording ? Colors.red : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)
                                          ],
                                        ),
                                        child: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.white : tPrimaryColor, size: 30),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // Upload Button
                                    DropTarget(
                                      onDragDone: (details) {
                                        if (details.files.isNotEmpty) {
                                          setState(() {
                                            _droppedFile = details.files.first;
                                            _userRecordingPath = null;
                                            _graphImage = null;
                                            _detectedKanji = "";
                                            _detectedRomaji = "";
                                            _aiScore = "";
                                            _combinedScore = "";
                                            _dtwScore = "";
                                          });
                                        }
                                      },
                                      onDragEntered: (details) => setState(() => _isHoveringDropZone = true),
                                      onDragExited: (details) => setState(() => _isHoveringDropZone = false),

                                      child: InkWell(
                                        onTap: _pickFile,
                                        borderRadius: BorderRadius.circular(50),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: _isHoveringDropZone ? Colors.blue.shade100 : (_droppedFile != null ? Colors.green.shade100 : Colors.white),
                                            shape: BoxShape.circle,
                                            border: _isHoveringDropZone ? Border.all(color: Colors.blue, width: 2) : null,
                                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)],
                                          ),
                                          child: Icon(_droppedFile != null ? Icons.check : Icons.upload, color: _droppedFile != null ? Colors.green : Colors.grey, size: 28),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // Playback
                                    if ((_userRecordingPath != null || _droppedFile != null) && !_isRecording)
                                      ElevatedButton.icon(
                                        onPressed: _playUserContent,
                                        icon: const Icon(Icons.play_arrow),
                                        label: Text(_droppedFile != null ? "Play File" : "Play Rec"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),

                                // Instructions
                                if (_isRecording)
                                  const Padding(padding: EdgeInsets.only(top: 10), child: Text("Recording...", style: TextStyle(color: Colors.red)))
                                else if (_droppedFile != null)
                                  Padding(padding: const EdgeInsets.only(top: 10), child: Text("Ready: ${_droppedFile!.name}", style: const TextStyle(color: Colors.green, fontSize: 12)))
                                else
                                  const Padding(padding: EdgeInsets.only(top: 10), child: Text("Tap Mic or Upload Audio", style: TextStyle(color: Colors.grey, fontSize: 12))),

                                const SizedBox(height: 20),

                                /*----------------- ANALYZE SECTION -----------------*/
                                if ((_userRecordingPath != null || _droppedFile != null) && !_isRecording)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isAnalyzing ? null : () => _generateGraph(currentCard),
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

                                /*----------------- RESULT GRAPH & TEXT -----------------*/
                                if (_graphImage != null)
                                  Column(
                                    children: [
                                      // Graph Image
                                      Container(
                                        height: 400,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.white,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            _graphImage!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 15),

                                      // --- NEW GREEN AI SCORE BOX ---
                                      if (_combinedScore.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            border: Border.all(color: Colors.green.shade400, width: 2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "AI Match Score: $_combinedScore",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),

                                      if (_combinedScore.isNotEmpty) const SizedBox(height: 15),

                                      // --- NEW Blue DTW SCORE BOX ---
                                      if (_aiScore.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            border: Border.all(color: Colors.green.shade400, width: 2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "AI Match Score: $_aiScore",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),

                                      if (_aiScore.isNotEmpty) const SizedBox(height: 15),
                                      // ------------------------------

                                      // --- NEW orange DTW SCORE BOX ---
                                      if (_dtwScore.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            border: Border.all(color: Colors.green.shade400, width: 2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "AI Match Score: $_dtwScore",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),

                                      if (_dtwScore.isNotEmpty) const SizedBox(height: 15),
                                      // Transcription Text using google speech to text
                                      Text(
                                        "Detected: $_detectedRomaji",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _detectedKanji,
                                        style: const TextStyle(
                                            fontSize: 32, // Size
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Next Word", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- DEMO SECTION ---
                      const Divider(),
                      const Text("Demo Mode", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDemoButton("watashi_female.mp3", "Watashi (female)"),
                            const SizedBox(width: 10),
                            _buildDemoButton("watashi_male.mp3", "watashi (male)"),
                            const SizedBox(width: 10),
                            _buildDemoButton("watashi_wrong.mp3", "watashi (wrong pitch)"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildDemoButton(String fileName, String label) {
    return OutlinedButton.icon(
      onPressed: () => _loadDemoFile(fileName),
      icon: const Icon(Icons.science, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.purple,
        side: const BorderSide(color: Colors.purple),
      ),
    );
  }
}