import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myapp/src/common_widgets/shop_card_view.dart';
import 'package:myapp/src/constants/image_strings.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/constants/text_strings.dart';
import 'package:myapp/src/features/authentication/screens/register/register_form_user_widget.dart';
import 'package:myapp/src/features/authentication/screens/register/register_form_school_widget.dart';
import 'package:myapp/src/features/authentication/screens/register/toggle_button_widget.dart';
import 'package:myapp/src/features/authentication/screens/welcome/welcome_screen.dart';

import '../../../../common_widgets/form/form_header_widget.dart';
import '../login/Login_form_widget.dart';
import '../login/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      //keeps the img, text and widgets withing the screens safe area
      child: Scaffold(
        body: SingleChildScrollView(
          //single child scrollable
          child: Container(
              padding: const EdgeInsets.all(tDefaultSize),
              //default padding size
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, //align all
                children: [
                  //img and heading
                  FormHeaderWidget(
                      image: tWelcomeScreenImg,
                      title: tRegisterTitle,
                      subTitle: tRegisterSubTitle,
                      deviceHeight: deviceHeight),

                  //spacing
                  SizedBox(
                    height: 10.0,
                  ),

                  //toggle button
                  ToggleButtonWidget(deviceHeight: deviceHeight),

                  //form to Register with "already have an account"
                  //RegisterFormSchool(),

                  //footer
                  /*Column(
                children: [
                  const Text("OR"),
                  SizedBox(
                    width: double.infinity,
                    height: tButtonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Image(
                        image: AssetImage(tGoogleImg),
                        width: 20.0,
                      ),
                      label: const Text(tSignInWithGoogle),
                    ), // OutlinedButton.icon
                  ),*/

                  /*----------------Already have an account? -------------- */
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                        onPressed: () => Get.to(() => LoginScreen()),
                        child: Text(
                          tAlreadyHaveAccount,
                          style: TextStyle(color: Colors.blue),
                        )),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
