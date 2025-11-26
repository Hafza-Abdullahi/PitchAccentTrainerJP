import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/src/constants/global_variables.dart';
import 'package:myapp/src/constants/image_strings.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/constants/text_strings.dart';
import 'package:myapp/src/features/authentication/screens/login/login_screen.dart';

import '../home/home_screen.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(tDefaultSize),
        child: Column(
          //container view
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, //SPACE EVENLY AROUND SCREEN
          children: [
            /* -----------------IMAGES -------------------------------------*/
            Column(
              children: [
                Align(
                  alignment: Alignment.topLeft, //align to top left
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Image(image: AssetImage(tSplashLogoImg)),
                  ),
                ),
                Align(
                  alignment: Alignment.center, //align to center of page
                  child: SizedBox(
                    child: Image(
                      image: AssetImage(tWelcomeScreenImg),
                      height: deviceHeight * 0.4,
                    ),
                  ),
                ),
              ],
            ),

            /*---------------------------------TEXT---------------------------*/
            Column(
              //column to keep text together
              children: [
                Text(tWelcomeTitle), //main title
                Text(tWelcomeSubTitle), //subheading
              ],
            ),

            /*--------------------------------BUTTONS-------------------------*/
            Row(
              //container for buttons
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Get.to(() => const LoginScreen()),
                        child: Text(tLogin
                            .toUpperCase())) //uppercase for easier readability
                    ),
                SizedBox(
                  width: 10.0,
                ), //spacing between buttons
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => Get.to(() => const HomeScreen()),
                        child: Text(tRegister.toUpperCase()))),
              ],
            ),
            //SizedBox(
              //height: 10.0,),

            ElevatedButton(
              onPressed: () {
                //go to homescreen
                Get.to(() => const HomeScreen());// Navigate to NavigationMenu

              },
              child: Text("Continue Without Logging In".toUpperCase()), // Change text to your needs
            ),
          ],
        ),
      ),
    );
  }
}
