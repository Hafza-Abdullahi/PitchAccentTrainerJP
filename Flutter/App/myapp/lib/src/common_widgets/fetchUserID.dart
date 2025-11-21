import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/global_variables.dart';

class FetchUserID {
  late String userID = "";
  Future<void> loadProfileData() async {
    try {
      //get the current user ID
      userID = FirebaseAuth.instance.currentUser?.uid ?? '';
      print("-----------------------------------------------userID WAS FETCHED--------------------------------------"+userID);


    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  getCurrentUserID(){
    return userID;
  }

}