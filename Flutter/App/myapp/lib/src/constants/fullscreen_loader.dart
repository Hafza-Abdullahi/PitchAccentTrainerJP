import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TFullscreenLoader {
  static void showLoadingDialogue(String text) {

    showDialog(
      context: Get.overlayContext!, //! means overlay context can be null but current isnt
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.5), // Dim background, alf transparent
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void stopLoading() {
    if (Get.isDialogOpen!) Get.back();
  }
}
