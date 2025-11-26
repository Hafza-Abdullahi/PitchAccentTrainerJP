import 'package:flutter/material.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:myapp/src/constants/shadows.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("inside homesscreen");
    return SafeArea(
      child: Scaffold(
        backgroundColor: tBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(tDefaultSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const SizedBox(height: tDefaultSize),

              /// WORD AREA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(tCardPadding),
                decoration: BoxDecoration(
                  color: tCardBgWord,
                  borderRadius: BorderRadius.circular(tCardRadius),
                  boxShadow: [TshadowStyle.shopCardViewShadow],
                ),
                child: const Text(
                  "Word goes here",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tWordTextSize,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: tHomeVerticalSpacing),

              /// MEANING AREA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(tCardPadding),
                decoration: BoxDecoration(
                  color: tCardBgMeaning,
                  borderRadius: BorderRadius.circular(tCardRadius),
                  boxShadow: [TshadowStyle.shopCardViewShadow],
                ),
                child: const Text(
                  "Meaning goes here",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tMeaningTextSize,
                    color: textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: tHomeVerticalSpacing),

              /// IMAGE AREA
              Container(
                height: tImageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tCardBgImage,
                  borderRadius: BorderRadius.circular(tCardRadius),
                  boxShadow: [TshadowStyle.shopCardViewShadow],
                ),
                child: const Center(
                  child: Text(
                    "Image Placeholder",
                    style: TextStyle(
                      fontSize: tPlaceholderTextSize,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
