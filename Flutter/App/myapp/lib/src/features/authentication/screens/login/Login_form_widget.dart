import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:myapp/src/common_widgets/navigation_menu.dart';
import 'package:myapp/src/features/authentication/controllers/login_controller.dart';
import 'package:myapp/src/features/authentication/exceptions/form_validator.dart';

import '../../../../constants/global_variables.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../welcome/welcome_screen.dart';

class LoginForm extends StatefulWidget {
  //stateful widget so its rerender after ever key with observer
  const LoginForm({
    super.key,
  });

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final controller = Get.put(LoginController());

  //private key for form
  final _loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    //form
    return Form(
        key: _loginFormKey, //key
        child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: tFormHeight -
                    10), //formHeigh is 30, default sizing for padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*-----------------TEXT FIELD EMAIL----------------- */
                TextFormField(
                  //autofocus: true,  //focuses first input box, removes keyboard input being cancelled too
                  controller: controller.loginEmail,
                  //validator
                  validator: (value) => FormValidator.validateEmail(value),
                  decoration: InputDecoration(
                      //input box decoration
                      prefixIcon: Icon(Icons.person_outline_outlined), //icon
                      labelText: tEmail,
                      hintText: tEmail, //placeholder
                      border: OutlineInputBorder()),
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                Obx(
                  //observe
                  () => TextFormField(
                    controller: controller.loginPassword,
                    //validator // check if empty only
                    validator: (value) =>
                        FormValidator.validateEmptyText(tPassword, value),
                    obscureText: controller.hidePassword.value,
                    decoration: InputDecoration(
                        //input box decoration
                        prefixIcon: Icon(Icons.fingerprint),
                        //icon
                        labelText: tPassword,
                        hintText: tPassword,
                        //placeholder
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                            onPressed: () => controller.hidePassword.value =
                                !controller.hidePassword.value,
                            // true by default
                            icon: Icon(controller.hidePassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility))),
                  ),
                ),

                const SizedBox(
                  height: tFormHeight,
                ), //padding

                /*----------------Forgot password-------------- */
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      TextButton(onPressed: null, child: Text(tForgotPassword)),
                ),

                /*---------------Login Button----------------- */
                SizedBox(
                  width: double.infinity,
                  height: tButtonHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = controller.loginEmail.text.trim();
                      final password = controller.loginPassword.text.trim();

                      final authRepo = AuthenticationRepository.instance;
                      final error = await authRepo.loginWithEmailAndPassword(
                          email, password);

                      if (error != null) {
                        // Show error message
                        Get.snackbar(
                          "Login Failed",
                          error,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        // Login successful, go to home screen
                        // First check if user is a School User
                        final schoolUserQuery = await FirebaseFirestore.instance
                            .collection('SchoolUsers')
                            .where('SchoolEmail', isEqualTo: email)
                            .limit(1)
                            .get();

                        if (schoolUserQuery.docs.isNotEmpty) {
                          myGlobal_AccountType = "School User";
                          myGlobal_isNormalUser = false;
                          print("✅ School User logged in");
                        } else {
                          // If not school user, assume normal user
                          myGlobal_AccountType = "User";
                          myGlobal_isNormalUser = true;
                          print("✅ User logged in");
                        }

                        Get.back(); // Close loading dialog
                        Get.offAll(() => const NavigationMenu());
                      }
                    }, //go to main page/ currently goes to navigation
                    child: Text(tLogin.toUpperCase()), // button text
                  ),
                ),
              ],
            )));
  }
}
