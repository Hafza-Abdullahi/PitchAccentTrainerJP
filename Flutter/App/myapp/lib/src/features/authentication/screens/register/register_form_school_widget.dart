import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myapp/src/common_widgets/navigation_menu.dart';
import 'package:myapp/src/features/authentication/controllers/school_register_controller.dart';
import 'package:myapp/src/features/authentication/models/SchoolUserModel.dart';
import '../../../../constants/global_variables.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import '../../exceptions/form_validator.dart';
import '../login/login_screen.dart';
import '../welcome/welcome_screen.dart';

class RegisterFormSchool extends StatefulWidget {
  //stateful widget
  const RegisterFormSchool({
    super.key,
  });


  @override
  _RegisterFormSchool createState() => _RegisterFormSchool();
}

class _RegisterFormSchool extends State<RegisterFormSchool> {
  //access controller
  final controller = Get.put(RegisterControllerSchool());

  //private key for form
  final _registerFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _registerFormKey,
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: tFormHeight - 10),
            //formHeight is 30, default sizing for padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*-----------------TEXT FIELD: Full name ----------------- */
                TextFormField(
                  //autofocus: true,  //focuses first input box, removes keyboard input being cancelled too
                  controller: controller.registerSchoolFullName,
                  //store and retrieve field
                  decoration: InputDecoration(
                      //inputbox decoration
                      prefixIcon: Icon(Icons.person_outline_outlined), //icon
                      labelText: tFullNameSchool,
                      hintText: tFullNameSchool, //placeholder
                      border: OutlineInputBorder()),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Full Name is required' : null,
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                /*-----------------TEXT FIELD: Email ----------------- */
                TextFormField(
                  controller: controller.registerSchoolEmail,
                  //store and retrieve field
                  decoration: InputDecoration(
                      //inputbox decoration
                      prefixIcon: Icon(Icons.email_outlined), //icon
                      labelText: tEmail,
                      hintText: tEmailPlaceholder, //placeholder
                      border: OutlineInputBorder()),
                  //validation check for both null and empty string
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Email is required'
                      : null,
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                /*-----------------TEXT FIELD: Phone number ----------------- */
                TextFormField(
                  controller: controller.registerSchoolPhoneNo,
                  //store and retrieve field
                  decoration: InputDecoration(
                      //inputbox decoration
                      prefixIcon: Icon(Icons.numbers), //icon
                      labelText: tPhoneNum,
                      hintText: tPhoneNumPlaceholder, //placeholder
                      border: OutlineInputBorder()),
                  //validation check for both null and empty string
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'PhoneNo is required' : null,
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                /*-----------------TEXT FIELD: password ----------------- */
                Obx(
                  //observe
                  () => TextFormField(
                    controller: controller.registerSchoolPassword,
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

                /*---------------Register Button----------------- */
                SizedBox(
                  width: double.infinity,
                  height: tButtonHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_registerFormKey.currentState!.validate()) {
                        // Show a loading indicator (highly recommended)
                        Get.dialog(Center(child: CircularProgressIndicator()),
                            barrierDismissible: false);

                        //declare ref to doc
                        DocumentReference? reservedDocRef;

                        try {
                          //find an affliate link that isnt false
                          final Map<String, dynamic>? reservationResult = await RegisterControllerSchool.instance.getAndReserveTrackingId();

                          //error check
                          if (reservationResult == null || reservationResult['error'] != null) {
                            Get.back(); // Close the loading dialog
                            Get.snackbar("Registration Failed", reservationResult?['error'] ?? "Unknown error during reservation.");
                            return;
                          }

                          //get both id and email
                          final String reservedTrackingId = reservationResult['trackingId'];
                          reservedDocRef = reservationResult['docRef']; // Store for potential rollback

                          // we have id, continue with account
                          final email = controller.registerSchoolEmail.text.trim();
                          final password = controller.registerSchoolPassword.text.trim();
                          final String schoolName = controller.registerSchoolFullName.text.trim();

                          //register schooluser
                          final authError = await RegisterControllerSchool.instance.registerUser(email, password);

                          //account is not made, change id to false
                          if (authError != null) {
                            //change id to false
                            if (reservedDocRef != null) {
                              await reservedDocRef.update({'isAssigned': false});
                              print("Changed tracking ID Back to default assignment for document: ${reservedDocRef.id}");
                            }
                            //error
                            Get.back(); // Close the loading dialog
                            Get.snackbar("Registration Failed", authError);

                          } else {
                            print("*************************************USER ACCOUNT BEING MADE********************");
                            String currentUserID = FirebaseAuth.instance.currentUser!.uid;

                            //create school and add id to the school
                            final schoolUser = SchoolUserModel(
                              schoolFullName: controller.registerSchoolFullName.text.trim(),
                              schoolEmail: controller.registerSchoolEmail.text.trim(),
                              schoolPhoneNo: controller.registerSchoolPhoneNo.text.trim(),
                              schoolPassword: controller.registerSchoolPassword.text.trim(),
                              trackingID: reservedTrackingId, //reserved id
                            );

                            await controller.finalizeTrackingAssignment(reservedDocRef!, currentUserID, schoolName );


                            print("*************ACCOUNT MADE WITH THE USER ID: " + currentUserID + " *****************");

                            //create user once id is sorted
                            await controller.createSchoolUser(schoolUser);

                            Get.back(); //back
                            Get.off(() => const NavigationMenu()); // main page
                            myGlobal_isNormalUser = false;
                            myGlobal_AccountType = "School User";
                          }
                        }  catch (e) {
                          //CATCH any other error and rollback
                          if (reservedDocRef != null) {
                            try {
                              await reservedDocRef.update({'isAssigned': false});
                              print("Rolled back tracking ID assignment due to unexpected error.");
                            } catch (rollbackError) {
                              print("Failed to rollback during error handling: $rollbackError");
                            }
                          }
                          Get.back(); // Close the loading dialog on error
                          Get.snackbar("Error", "An unexpected error occurred: $e");
                          print("Unexpected error during registration: $e");
                        }
                      }
                    },
                    // go to main page/ currently goes to navigation
                    child: Text(tRegister.toUpperCase()), // button text
                  ),
                ),
              ],
            )));
  }

  

}
