import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myapp/src/constants/image_strings.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/constants/text_strings.dart';
import 'package:myapp/src/features/authentication/screens/welcome/welcome_screen.dart';

import '../../controllers/login_controller.dart';
import 'Login_form_widget.dart';
import '../../../../common_widgets/form/form_header_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController()); //import controller

    var deviceHeight = MediaQuery.of(context).size.height;
    return SafeArea(
        //keeps the img, text and widgets withing the screens safe area
        child: Scaffold(
      body: SingleChildScrollView(
        //singlechild scrollable
        child: Container(
          padding: const EdgeInsets.all(tDefaultSize), //default padding size
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //img and heading

              FormHeaderWidget(image: tWelcomeScreenImg, title: tLoginTitle, subTitle: tWelcomeSubTitle, deviceHeight: deviceHeight),
              //form to login with button and forget password
              LoginForm(),

              //footer
              //footer
              Column(
                children: [
                  const Text("OR"),
                  SizedBox(
                    width: double.infinity,
                    height: tButtonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.googleSignIn(),
                      icon: const Image(image: AssetImage(tGoogleImg), width: 20.0,),
                      label: const Text(tSignInWithGoogle),
                    ), // OutlinedButton.icon
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ));
  }
}



