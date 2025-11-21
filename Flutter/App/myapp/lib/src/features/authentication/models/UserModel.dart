
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {

  final String? UserID; //id will be added automatically
  final String UserSchoolName; //school user selects from drop down option
  final String UserFullName;
  final String UserEmail;
  final String UserPhoneNo;
  String UserPassword; //can be changed so not final

  UserModel({
    this.UserID,
    required this.UserSchoolName,
    required this.UserFullName,
    required this.UserEmail,
    required this.UserPhoneNo,
    required this.UserPassword,

  });

  toJsonUser(){
    return{
      "UserSchoolName": UserSchoolName,
      "UserFullName": UserFullName,
      "UserEmail": UserEmail,
      "UserPhoneNo": UserPhoneNo,
      "UserPassword": UserPassword,
    };
  }

  //fetch data from firebase, using a factory object
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document){
    final data = document.data()!;  //data object
    return UserModel(
        UserID: document.id,
        UserSchoolName: data['UserSchoolName'],
        UserFullName: data['SchoolName'],
        UserEmail: data['SchoolEmail'],
        UserPhoneNo: data['SchoolPhone'],
        UserPassword: data['SchoolPassword']);
  }


  getUserName() {
    return UserFullName;
  }
}