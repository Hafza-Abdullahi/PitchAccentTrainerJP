import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:myapp/src/repository/authentication_repository/authentication_repository.dart';

import '../../../repository/user_repository/user_repository.dart';
import '../exceptions/signup_email_password_failure.dart';
import '../models/UserModel.dart';

class RegisterControllerUser extends GetxController {
  //static instance to only use one instance
  static RegisterControllerUser get instance => Get.find();
  final userRepo = Get.put(UserRepository());

  //controllers for input fields
  final registerUserSchoolName = TextEditingController();
  final registerUserFullName = TextEditingController();
  final registerUserEmail = TextEditingController();
  final registerUserPhoneNo = TextEditingController();
  final registerUserPassword = TextEditingController();

  //password observer for getx var
  final hidePassword = true.obs;

  //func to register user
  Future<String?> registerUser(String email, String password) async {
    try {
      await AuthenticationRepository.instance
          .createUserWithEmailAndPassword(email, password);
      return null; // success
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      return e.message; // show this in the snackbar
    } catch (_) {
      return "An unknown error occurred.";
    }
  }

  //call func to create user using createNormal
  Future<void> createNormalUser(UserModel user) async {
    print("GOUNG INTO NORMAL USER");
    await userRepo.createNormalUser(user); //future, waits for user to be created in createNormalUser
  }

}
