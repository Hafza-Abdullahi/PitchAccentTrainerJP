import 'dart:io'; // Needed for File
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:path_provider/path_provider.dart'; // To find where to save audio
import 'package:record/record.dart'; // The recording package
import 'package:audioplayers/audioplayers.dart'; // To play back user audio

import '../../../../common_widgets/card/word_card.dart';
import '../../../../repository/anki_repository/anki_repository.dart';
import '../../../../utils/anki_audio_player.dart';
import '../../models/anki_card_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /******************** VARIABLES *******************/
  final AnkiRepository _repository = AnkiRepository();
  final AnkiAudioPlayer _nativeAudioPlayer = AnkiAudioPlayer(); // Plays the native Japanese

  // -- Recorder Variables --
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _userAudioPlayer = AudioPlayer(); // Plays the user's voice

  //indexing cards
  int _currentIndex = 0;

  //future variable to cache data
  late Future<List<AnkiCardModel>> _cardsFuture;

  // -- Recorder State --
  bool _isRecording = false;
  String? _userRecordingPath; // Stores the path of the user's recording

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

  /******************** RECORDER LOGIC *******************/
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {

        // --- WEB ONLY CONFIGURATION ---
        if (kIsWeb) {
          // Web needs Opus usually. AAC often crashes Chrome.
          await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.opus),
              path: '' // Passing empty string lets the browser handle memory
          );
        }
        // --- MOBILE CONFIGURATION ---
        else {
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
        print("Microphone started");
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop returns the path where the file was saved
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _userRecordingPath = path; // Save the path so we can play it
      });
    } catch (e) {
      print("Error stopping record: $e");
    }
  }

  Future<void> _playUserRecording() async {
    try {
      if (_userRecordingPath != null) {
        // DeviceFileSource is for Mobile/Desktop files
        // UrlSource is usually returned by Web recorders
        Source urlSource = (kIsWeb)
            ? UrlSource(_userRecordingPath!)
            : DeviceFileSource(_userRecordingPath!);

        await _userAudioPlayer.play(urlSource);
      }
    } catch (e) {
      print("Error playing user audio: $e");
    }
  }

  /******************** CARD LOGIC *******************/
  void _nextCard(int totalCards) {
    setState(() {
      // Reset user recording when moving to a new card
      _userRecordingPath = null;
      _isRecording = false;

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
        // CENTER EVERYTHING
        body: Center(
          //constrain width for web and tablet views
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FutureBuilder<List<AnkiCardModel>>(
              future: _cardsFuture,
              builder: (context, snapshot) {
                /*----------------- LOADING STATE -----------------*/
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                /*----------------- ERROR STATE -----------------*/
                else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                /*----------------- EMPTY STATE -----------------*/
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No cards found."));
                }

                //data loaded successfully
                final cards = snapshot.data!;
                final currentCard = cards[_currentIndex];

                return Padding(
                  padding: const EdgeInsets.all(tDefaultSize),
                  child: Column(
                    children: [
                      /*----------------- PROGRESS INDICATOR -----------------*/
                      Text(
                        "Card ${_currentIndex + 1} of ${cards.length}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      /*----------------- CARD AREA -----------------*/
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                WordCard(
                                  card: currentCard,
                                  onPlayAudio: () => _nativeAudioPlayer.play(currentCard.wordAudio),
                                ),

                                const SizedBox(height: 20),

                                /*----------------- INPUT AUDIO (RECORDER) -----------------*/
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 1. Record Button
                                    GestureDetector(
                                      onLongPress: _startRecording, // Hold to record
                                      onLongPressUp: _stopRecording, // Release to stop
                                      onTap: () {
                                        // Tap support (Tap start / Tap stop)
                                        if (_isRecording) {
                                          _stopRecording();
                                        } else {
                                          _startRecording();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: _isRecording ? Colors.red : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                          ],
                                        ),
                                        child: Icon(
                                          _isRecording ? Icons.stop : Icons.mic,
                                          color: _isRecording ? Colors.white : tPrimaryColor,
                                          size: 30,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // 2. Playback Button (Only shows if recording exists)
                                    if (_userRecordingPath != null && !_isRecording)
                                      ElevatedButton.icon(
                                        onPressed: _playUserRecording,
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text("My Voice"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),
                                if (_isRecording)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text("Recording...", style: TextStyle(color: Colors.red)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: tDefaultSize),

                      /*----------------- NEXT BUTTON -----------------*/
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _nextCard(cards.length),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Next Word",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
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