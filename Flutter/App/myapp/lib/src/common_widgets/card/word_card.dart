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
              color: tCardBgWord, // Make sure this is defined in colours.dart
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

          /// --- AUDIO BUTTON SECTION ---
          if (card.wordAudio.isNotEmpty)
            Container(
              color: Colors.grey.withOpacity(0.1),
              child: IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: tPrimaryColor),
                onPressed: onPlayAudio,
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