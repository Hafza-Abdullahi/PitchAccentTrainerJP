import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/src/constants/image_strings.dart';
import 'package:myapp/src/features/authentication/controllers/splash_screen_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final splashScreenController = Get.put(SplashScreenController());

  @override
  Widget build(BuildContext context) {
    splashScreenController.startAnimation();
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center, //align to center of page
            child: SizedBox(
              width: 150, // Set your desired width
              height: 150, // Set your desired height
              child: Image(image: AssetImage(tSplashLogoImg)),
            ),
          ),
        ],
      ),
    );
  }
}
