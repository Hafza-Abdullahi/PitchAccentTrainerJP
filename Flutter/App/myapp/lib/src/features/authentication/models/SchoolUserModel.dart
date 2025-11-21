import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/src/features/authentication/models/UserModel.dart';

class SchoolUserModel {

  final String? schoolID; //id will be added automatically
  String? SchoolUserID;
  final String schoolFullName;
  final String schoolEmail;
  final String schoolPhoneNo;
  String schoolPassword; //can be changed so not final
  final String trackingID;

  SchoolUserModel({
    this.schoolID,
    //required this.SchoolUserID,
    required this.schoolFullName,
    required this.schoolEmail,
    required this.schoolPhoneNo,
    required this.schoolPassword,
    required this.trackingID,

  });


  toJsonSchool() {
    return {
      //"SchoolUserID" : SchoolUserID,
      "SchoolName": schoolFullName,
      "SchoolEmail": schoolEmail,
      "SchoolPhone": schoolPhoneNo,
      "SchoolPassword": schoolPassword,
      "trackingID": trackingID,
    };
  }

  //fetch data from firebase, using a factory object
  factory SchoolUserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document){
    final data = document.data()!;  //data object
    return SchoolUserModel(
        schoolID: document.id,
        //SchoolUserID: data['SchoolUserID'],
        schoolFullName: data['SchoolName'],
        schoolEmail: data['SchoolEmail'],
        schoolPhoneNo: data['SchoolPhone'],
        schoolPassword: data['SchoolPassword'],
        trackingID: data['trackingID']);
  }


  getSchoolName() {
    return schoolFullName;
  }
}