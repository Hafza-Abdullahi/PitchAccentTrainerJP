import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:myapp/src/constants/shadows.dart';
import 'package:myapp/src/constants/sizes.dart';
import '../../features/authentication/models/anki_card_model.dart';

class WordCard extends StatelessWidget {
  final AnkiCardModel card;
  final VoidCallback? onPlayAudio;

  const WordCard({
    super.key,
    required this.card,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: tHomeVerticalSpacing),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tCardRadius),
        boxShadow: [TshadowStyle.shopCardViewShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// --- WORD SECTION ---
          Container(
            padding: const EdgeInsets.all(tCardPadding),
            decoration: BoxDecoration(
              color: tCardBgWord, // Background color for the word section
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(tCardRadius),
                topRight: Radius.circular(tCardRadius),
              ),
            ),
            child: Column(
              children: [
                Text(
                  card.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: tWordTextSize,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  card.wordReading,
                  style: const TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          /// --- NATIVE AUDIO BUTTON SECTION ---
          if (card.wordAudio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                // StatefulBuilder allows for local state management (hover) in a stateless widget
                child: StatefulBuilder(
                  builder: (context, setState) {
                    bool isHovered = false;
                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          // Changes background opacity based on hover state
                          color: isHovered
                              ? Colors.purple.withOpacity(0.15)
                              : Colors.purple.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            // Changes border visibility based on hover state
                            color: isHovered ? Colors.purple : Colors.purple.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: isHovered ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ] : [],
                        ),
                        child: InkWell(
                          onTap: onPlayAudio,
                          borderRadius: BorderRadius.circular(50),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: Colors.purple,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          /// --- MEANING SECTION ---
          Container(
            padding: const EdgeInsets.all(tCardPadding),
            color: tCardBgMeaning,
            child: Column(
              children: [
                const Text(
                  "Meaning",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  card.wordMeaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: tMeaningTextSize,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// --- SENTENCE SECTION ---
          if (card.sentence.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(tCardPadding),
              child: Column(
                children: [
                  const Divider(),
                  const Text("Example:",
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    card.sentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}