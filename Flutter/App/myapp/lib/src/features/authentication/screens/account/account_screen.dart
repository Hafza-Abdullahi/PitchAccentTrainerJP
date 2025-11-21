import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../constants/global_variables.dart';
import '../../../../repository/authentication_repository/authentication_repository.dart';
import '../welcome/welcome_screen.dart';
import 'edit_account_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String userFullName = '';
  String userSchoolName = '';
  String userEmail = '';
  String userPhone = '';
  String schoolName = '';
  String accountType = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      print("Current User Email: $currentUserEmail");

      if (currentUserEmail.isEmpty) {
        throw Exception("No user signed in");
      }

      // Collections
      String normalUserCollection = "NormalUsers";
      String schoolUserCollection = "SchoolUsers";

      // Search in NormalUsers
      QuerySnapshot normalQuery = await FirebaseFirestore.instance
          .collection(normalUserCollection)
          .where('UserEmail', isEqualTo: currentUserEmail)
          .get();

      //if its not empty, NormalUser
      if (normalQuery.docs.isNotEmpty) {
        accountType = "Normal";
        var data = normalQuery.docs.first.data() as Map<String, dynamic>;
        //fetch data
        setState(() { //get and temporarly save
          userFullName = data['UserFullName'] ?? '';
          userEmail = data['UserEmail'] ?? '';
          userPhone = data['UserPhoneNo'] ?? '';
          schoolName = data['UserSchoolName'] ?? '';
          _isLoading = false;

          // Save to globals
          myGlobal_isNormalUser = true;
          myGlobal_AccountType = accountType;
          myGlobal_userFullName = userFullName;
          myGlobal_userEmail = userEmail;
          myGlobal_userPhone = userPhone;
          myGlobal_schoolName = schoolName;

          print("GLOBA IN ACCOUNT SCREEN: " +  myGlobal_AccountType + myGlobal_userEmail +myGlobal_userPhone);

          print("fetched: $userFullName$userEmail$userPhone$schoolName");
        });
        return;
      }

      // Search in SchoolUsers
      QuerySnapshot schoolQuery = await FirebaseFirestore.instance
          .collection(schoolUserCollection)
          .where('SchoolEmail', isEqualTo: currentUserEmail)
          .get();

      if (schoolQuery.docs.isNotEmpty) {
        accountType = "School";
        var data = schoolQuery.docs.first.data() as Map<String, dynamic>;
        setState(() {
          userFullName = data['SchoolName'] ?? '';
          userEmail = data['SchoolEmail'] ?? '';
          userPhone = data['SchoolPhone'] ?? '';
          _isLoading = false;

          // Save to globals
          myGlobal_isNormalUser = false;
          myGlobal_AccountType = accountType;
          myGlobal_userFullName = userFullName;
          myGlobal_userEmail = userEmail;
          myGlobal_userPhone = userPhone;


          print("fetched: $userFullName$userEmail$userPhone$schoolName");
        });
        return;
      }

      throw Exception("Profile not found in either collection");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator() //load
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        myGlobal_AccountType,
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                    SizedBox(height: 20),

                    //NAME
                    ListTile(
                      title: Text(
                        "Name",
                      ),
                      subtitle: Text(userFullName),
                      leading: Icon(CupertinoIcons.person),
                      trailing: Icon(Icons.arrow_forward),
                      tileColor: Colors.white,
                    ),
                    SizedBox(height: 20),
                    //EMAIL
                    ListTile(
                      title: Text(
                        "Email",
                      ),
                      subtitle: Text(userEmail),
                      leading: Icon(CupertinoIcons.mail),
                      trailing: Icon(Icons.arrow_forward),
                      tileColor: Colors.white,
                    ),
                    SizedBox(height: 20),
                    //PHONE
                    ListTile(
                      title: Text(
                        "Phone",
                      ),
                      subtitle: Text(userPhone),
                      leading: Icon(CupertinoIcons.phone),
                      trailing: Icon(Icons.arrow_forward),
                      tileColor: Colors.white,
                    ),
                    SizedBox(height: 20),

                    //only show for user profiles, since user has a school name selected
                    if (accountType == "Normal")
                      ListTile(
                        title: Text(
                          "School Name",
                        ),
                        subtitle: Text(schoolName),
                        leading: Icon(CupertinoIcons.phone),
                        trailing: Icon(Icons.arrow_forward),
                        tileColor: Colors.white,
                      ),
                    SizedBox(height: 40),

                    //buttons for edit and logout
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  6), // less rounded corners
                            ),
                          ),
                          onPressed: () => Get.to(() => EditAccountScreen(accountType: accountType)),
                          child: Text("Edit Profile"),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(6), //
                              // same
                            ),
                            backgroundColor: Colors.blueAccent,

                          ),
                          onPressed: () async {
                            await AuthenticationRepository.instance.logout();
                            Get.offAll(() => WelcomeScreen());
                            resetGlobalVars();
                          },
                          child: Text("Logout"),
                        ),
                      ),
                    )

                  ],
                ),
        ),
      ),
    );
  }
}
