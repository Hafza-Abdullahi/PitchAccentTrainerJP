import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/src/features/authentication/models/SchoolUserModel.dart';

import '../../features/authentication/models/UserModel.dart';

//user repository class to do crud for database
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance; //get instance of db

  //takes in usermodel as a parameter, the classmodel for user info
  //normal users => parents, teachers, students
  createNormalUser(UserModel user) async {
    //asyn func
    await _db
        .collection("NormalUsers")
        .add(user.toJsonUser())
        .whenComplete(
      //popup for success
          () => Get.snackbar("Success", "Your account has been created!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white),
    )
        .catchError((error, stackTrace) {
      Get.snackbar("Error", "There was a problem with account creation",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      print(error.toString());
    });
  }

  //school users => school
  createSchoolUser(SchoolUserModel user) async {
    //asyn func
    await _db
        .collection("SchoolUsers")
        .add(user.toJsonSchool())
    // After SchoolUsers is created, add school name to to a separate collection
        .whenComplete(() async {
      await _db.collection("RegisteredSchoolNames").add({
        "SchoolName": user.getSchoolName() , // or whatever you want to store
      });
      Get.snackbar(
        "Success",
        "Your School User acc has been created",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
    },
    )
        .catchError((error, stackTrace) {
      Get.snackbar("Error", "There was a problem with account creation",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      print(error.toString());
    });
  }

  /* ---------------- UPDATE ---------------- */

  /// Update an existing normal user
  Future<void> updateNormalUser(String userId, UserModel updatedUser) async {
    await _db.collection("NormalUsers").doc(userId).update(updatedUser.toJsonUser()).whenComplete(
          () => Get.snackbar(
        "Success",
        "User details have been updated!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      ),
    ).catchError((error, stackTrace) {
      Get.snackbar(
        "Error",
        "Failed to update user details",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      print(error.toString());
    });
  }

  /// Update an existing school user
  Future<void> updateSchoolUser(String schoolId, SchoolUserModel updatedUser) async {
    await _db.collection("SchoolUsers").doc(schoolId).update(updatedUser.toJsonSchool()).whenComplete(
          () => Get.snackbar(
        "Success",
        "School user details have been updated!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      ),
    ).catchError((error, stackTrace) {
      Get.snackbar(
        "Error",
        "Failed to update school user details",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      print(error.toString());
    });
  }
}