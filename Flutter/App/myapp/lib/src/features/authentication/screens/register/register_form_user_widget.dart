import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myapp/src/common_widgets/navigation_menu.dart';
import 'package:myapp/src/constants/global_variables.dart';
import 'package:myapp/src/features/authentication/controllers/user_register_controller.dart';
import 'package:myapp/src/features/authentication/models/UserModel.dart';

import '../../../../common_widgets/fetchSchoolNamesDB.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import '../../exceptions/form_validator.dart';

class RegisterFormUser extends StatefulWidget {
  //stateful widget
  const RegisterFormUser({
    super.key,
  });

  @override
  _RegisterFormUser createState() => _RegisterFormUser();
}


class _RegisterFormUser extends State<RegisterFormUser> {
  //access controller
  final controller = Get.put(RegisterControllerUser());

  //private key for form
  final _registerFormKey = GlobalKey<FormState>();

  String? _dropdownValue; //selected value is null at the beginining

  List<String> _names = [];

  @override
  void initState() {
    super.initState();
    loadSchoolNames();
  }

  void loadSchoolNames() async {
    final names = await FetchSchoolNamesDB.fetchSchoolNames();
    print('------------------------------Fetched names: $names');
    setState(() {
      _names = names;
    });
  }


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
                /*-----------------SCHOOL SELECTOR-------------------------*/
                //drop down menu
                DropdownButtonFormField<String>(
                  value: _dropdownValue,
                  decoration: InputDecoration(
                    labelText: tDropdownSchoolText,
                    border: OutlineInputBorder(),
                  ),
                  items: _names.map((String item) { //map list of names to dropdown
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) { //update selected value
                    setState(() {
                      _dropdownValue = newValue!;
                      controller.registerUserSchoolName.text = newValue;
                    });
                  },
                  validator: (value) =>
                  value == null ? '-please select an option-' : null,
                ),
                SizedBox(height: 20),
                /*-----------------TEXT FIELD: Full name ----------------- */
                TextFormField(
                  //autofocus: true,  //focuses first input box, removes keyboard input being cancelled too
                  controller: controller.registerUserFullName,
                  //store and retrieve field
                  decoration: InputDecoration(
                      //inputbox decoration
                      prefixIcon: Icon(Icons.person_outline_outlined), //icon
                      labelText: tFullNameUser,
                      hintText: tFullNameUser, //placeholder
                      border: OutlineInputBorder()),
                  //validation check for both null and empty string
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Full name is required' : null,
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                /*-----------------TEXT FIELD: Email ----------------- */
                TextFormField(
                  controller: controller.registerUserEmail,
                  //store and retrieve field
                  decoration: InputDecoration(
                      //inputbox decoration
                      prefixIcon: Icon(Icons.email_outlined), //icon
                      labelText: tEmail,
                      hintText: tEmailPlaceholder, //placeholder
                      border: OutlineInputBorder()),
                  //validation check for both null and empty string
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Email is required' : null,
                ),

                const SizedBox(
                  height: tFormHeight - 20,
                ), //padding

                /*-----------------TEXT FIELD: Phone number ----------------- */
                TextFormField(
                  controller: controller.registerUserPhoneNo,
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
                    controller: controller.registerUserPassword,
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

                        final email = controller.registerUserEmail.text.trim();
                        final password =
                            controller.registerUserPassword.text.trim();

                        final error = await RegisterControllerUser.instance
                            .registerUser(email, password);

                        if (error != null) {
                          Get.snackbar(
                            "Registration Failed",
                            error,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          //validation is done, saves details to collection in database
                          final user = UserModel(
                              UserSchoolName: controller.registerUserSchoolName.text.trim(),
                              UserFullName: controller.registerUserFullName.text.trim(),
                              UserEmail: controller.registerUserEmail.text.trim(),
                              UserPhoneNo: controller.registerUserPhoneNo.text.trim(),
                              UserPassword: controller.registerUserPassword.text.trim());

                          //call func to make and save user details
                          RegisterControllerUser.instance.createNormalUser(user);
                          Get.to( () => const NavigationMenu());
                          myGlobal_isNormalUser = true; //user is a normal
                          myGlobal_AccountType = "User";
                        }


                      }
                    },

                    child: Text(tRegister.toUpperCase()), // button text
                  ),
                ),
              ],
            )));
  }
}
