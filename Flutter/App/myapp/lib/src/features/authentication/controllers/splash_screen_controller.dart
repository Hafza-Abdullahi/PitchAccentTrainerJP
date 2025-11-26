import 'package:get/get.dart';
import 'package:myapp/src/features/authentication/screens/welcome/welcome_screen.dart';

class SplashScreenController extends GetxController {
  static SplashScreenController get find => Get.find();

  Future startAnimation() async {
    print("Navigating to WelcomeScreen..."); // Debugging line
    await Future.delayed(Duration(milliseconds: 2000));
    print("Navigating to WelcomeScreen..."); // Debugging line
    Get.off(() =>
        WelcomeScreen()); // Replaces the current screen with WelcomeScreen
  }
}
