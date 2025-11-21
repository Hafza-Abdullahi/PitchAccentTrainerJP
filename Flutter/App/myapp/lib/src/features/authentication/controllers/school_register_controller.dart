import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:myapp/src/features/authentication/models/SchoolUserModel.dart';
import 'package:myapp/src/repository/authentication_repository/authentication_repository.dart';

import '../../../repository/user_repository/user_repository.dart';
import '../exceptions/signup_email_password_failure.dart';

class RegisterControllerSchool extends GetxController {
  //static instance to only use one instance
  static RegisterControllerSchool get instance => Get.find();
  final userRepo = Get.put(UserRepository());

  //controllers for input fields
  final registerSchoolFullName = TextEditingController();
  final registerSchoolEmail = TextEditingController();
  final registerSchoolPhoneNo = TextEditingController();
  final registerSchoolPassword = TextEditingController();

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

  //call func to create school user using createNormal
  Future<void> createSchoolUser(SchoolUserModel user) async {
    print("*******************GOUNG INTO SCHOOL USER***********************");
    await userRepo.createSchoolUser(user); //future, waits for user to be created in createSchoolUser
  }

  //*******************AFFLIATE LINK RESERVATION***************************
  Future<Map<String, dynamic>?> getAndReserveTrackingId() async {
    try { //look for collection that isnt assigned to a school already
      //limit is 1
      final querySnapshot = await FirebaseFirestore.instance
          .collection('TrackingLinks') // Your collection name
          .where('isAssigned', isEqualTo: false)
          .limit(1)
          .get();

      //search for docc
      if (querySnapshot.docs.isEmpty) {
        //simple map with error
        return {'error': "No affiliate tracking IDs available. Please try again later."};
      }
      final availableDoc = querySnapshot.docs.first; //first available
      final trackingId = availableDoc['AmazonTrackingID'] as String; //example schoolid4-20

      //change assigned to true so another school cant grab it
      await availableDoc.reference.update({'isAssigned': true});

      // Return both id and doc reference, NEED IT FOR LATER if school acc registration fails
      return {
        'trackingId': trackingId,
        'docRef': availableDoc.reference, // <-- This is the key for rollback
        'error': null,
      };

    } catch (e) { //no available link
      return {'error': "Failed to reserve affiliate tracking ID. Please try again."};
    }
  }

  //finalize assignment
  Future<void> finalizeTrackingAssignment(DocumentReference trackingDocRef, String schoolUID, String schoolUserName) async {
    try {
      // Update the tracking document with the school name
      await trackingDocRef.update({
        'SchoolUID': schoolUID, // Link the tracking ID and name to this specific school
        'SchoolNameLink': schoolUserName,
      });
      print("Successfully linked tracking ID to school UID: $schoolUserName, $schoolUID");
    } catch (e) {
      print("Error finalizing tracking assignment: $e");

      rethrow; //re throw the error
    }
  }
}
