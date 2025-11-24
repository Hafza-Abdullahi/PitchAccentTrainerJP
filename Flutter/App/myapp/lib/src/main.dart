import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/src/features/authentication/screens/login/login_screen.dart';
import 'package:myapp/src/features/authentication/screens/splash/splash_screen.dart';
import 'package:myapp/src/repository/authentication_repository/authentication_repository.dart';

void main() {
  //initilise firebase
  WidgetsFlutterBinding.ensureInitialized();
  //initialise with the current application before widgets
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then(
          (value) => Get.put(AuthenticationRepository())); //calls onReady() func to start the user listener
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(  //get function returns app
      theme: ThemeData(   //auto theme, white
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: SplashScreen() //const CircularProgressIndicator(), //to keep logged in
    );
  }
}
