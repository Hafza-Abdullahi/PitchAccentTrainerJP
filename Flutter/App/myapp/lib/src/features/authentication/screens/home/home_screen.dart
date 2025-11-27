import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:myapp/src/constants/sizes.dart';

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
  final AnkiAudioPlayer _audioPlayer = AnkiAudioPlayer();

  //indexing cards in deck to track current position
  int _currentIndex = 0;

  //future variable to cache data loading
  late Future<List<AnkiCardModel>> _cardsFuture;

  /******************** CYCLE METHODS *******************/
  //init function to load cards once app is opened
  @override
  void initState() {
    super.initState();
    _cardsFuture = _repository.loadLocalDeck();
  }

  //dispose function to release resources and audio player
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /******************** CARD LOGIC *******************/
  //next card function to cycle through cards
  //resets to 0 if end of list is reached
  void _nextCard(int totalCards) {
    setState(() {
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
          //constrain width for web and tablet views (max 600px)
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
                      //expanded area for the main card content
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: WordCard(
                              card: currentCard,
                              onPlayAudio: () => _audioPlayer.play(currentCard.wordAudio),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: tDefaultSize),

                      /*----------------- BUTTONS -----------------*/
                      //next button to trigger index change
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