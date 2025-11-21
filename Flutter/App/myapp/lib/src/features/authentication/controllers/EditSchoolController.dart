import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:myapp/src/features/authentication/models/SchoolUserModel.dart';
import 'package:myapp/src/repository/user_repository/user_repository.dart';

class UpdateControllerSchool extends GetxController {
  // Singleton instance
  static UpdateControllerSchool get instance => Get.find();

  final userRepo = Get.put(UserRepository());

  // Controllers for input fields, can only change email and phone number
  final updateSchoolEmail = TextEditingController();
  final updateSchoolPhoneNo = TextEditingController();


  // Password visibility observer
  //final hidePassword = true.obs;

  //load user details into form
  void loadUserData(SchoolUserModel user) {
    updateSchoolEmail.text = user.schoolEmail ?? '';
    updateSchoolPhoneNo.text = user.schoolPhoneNo ?? '';
    //no password, password will be changed by a reset password function
  }

  // Function to update user info in database
  Future<void> updateSchoolUser(String schoolID, SchoolUserModel user) async {
    print("***************UPDATING SCHOOL USER***************");
    await userRepo.updateSchoolUser(schoolID, user);
  }
}
