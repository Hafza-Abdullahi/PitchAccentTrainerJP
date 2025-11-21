import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/src/constants/global_variables.dart';

import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import '../../controllers/EditSchoolController.dart';
import '../../exceptions/form_validator.dart';
import '../../models/SchoolUserModel.dart';
import '../register/register_form_user_widget.dart';

class EditAccountScreen extends StatefulWidget {
  final String accountType; //track account type
  const EditAccountScreen(
      {super.key, required this.accountType}); //takes in acount type

  @override
  _EditAccountScreen createState() => _EditAccountScreen();

}

class _EditAccountScreen extends State<EditAccountScreen> {
  final controller = Get.put(UpdateControllerSchool());
  final _updateAccountForm = GlobalKey<FormState>();

  //temp store when emails are changed and when successful, update Global Variable
  String changedEmail = "";
  String changedPhone = "";
  String currentPassword = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForPassword());
  }

  Future<void> _askForPassword() async {
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false, // force user to enter password
      builder: (context) {
        return AlertDialog(
          title: Text('Re-enter your password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  // optionally show an error or just block closing
                  return;
                }
                currentPassword = passwordController.text;
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    print("GLOBALS: " +myGlobal_userEmail);
    print("GLOBALS: " + myGlobal_userPhone);
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile for $myGlobal_userEmail"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(tFormHeight - 10),
            child: Form(
              key: _updateAccountForm,
              child: Column(
                children: [
                  if (widget.accountType == "Normal") ...[
//Normal User Form
                    //RegisterFormUser(),
                    Container(
                      child: Column(
                        children: [
                          // EMAIL (editable)
                          TextFormField(
                            //controller for observing and getting text
                            //controller: controller.updateSchoolEmail,
                            initialValue: myGlobal_userEmail,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(CupertinoIcons.mail),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                changedEmail = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // PHONE (editable)
                          TextFormField(
                            //controller for observing and getting text
                            //controller: controller.updateSchoolPhoneNo,
                            initialValue: myGlobal_userPhone,
                            decoration: InputDecoration(
                              labelText: "Phone",
                              prefixIcon: Icon(CupertinoIcons.phone),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                changedPhone = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),
//UPDATE BUTTON
                          ElevatedButton(
                            onPressed: () async {
                              final controller = UpdateControllerSchool.instance;

                              //get current email
                              String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

                              try {
                                //find the doc woth that exact email
                                final query = await FirebaseFirestore.instance
                                    .collection("NormalUsers")
                                    .where('UserEmail', isEqualTo: myGlobal_userEmail)
                                    .get();
                                //if empty
                                if (query.docs.isEmpty) {
                                  Get.snackbar("Error", "Normal user not found");
                                  return;
                                }

                                String docId = query.docs.first.id;


                                String emailToSave = changedEmail.isEmpty ? myGlobal_userEmail : changedEmail;
                                String phoneToSave = changedPhone.isEmpty ? myGlobal_userPhone : changedPhone;



                                User? user = FirebaseAuth.instance.currentUser;
                                // Reauthenticate user with current email and entered password
                                AuthCredential credential = EmailAuthProvider.credential(
                                  email: user!.email!,
                                  password: currentPassword,
                                );

                                try {
                                  await user.reauthenticateWithCredential(credential);

                                  // Now update email
                                  await user.verifyBeforeUpdateEmail(emailToSave);


                                  // Update Firestore after email update
                                  await FirebaseFirestore.instance.collection("NormalUsers").doc(docId).update({
                                    'UserEmail': emailToSave.trim(),
                                    'UserPhoneNo': phoneToSave.trim(),
                                  });

                                  myGlobal_userEmail = emailToSave;
                                  myGlobal_userPhone = phoneToSave;

                                  //successfully updated
                                  Get.snackbar("Success", "Email and profile updated successfully.");

                                } catch (e) {
                                  print("Reauth or updateEmail failed: $e");
                                  Get.snackbar("Error", "Failed to update email. Please check your password and try again.");
                                }

                              } catch (e) {
                                print("Error updating Normal user: $e");
                                Get.snackbar("Error", "Failed to update profile");
                              }
                            },
                            child: Text("Done"),
                          )
                        ],
                      ),
                    )

                  ] else if (widget.accountType == "School") ...[
//School Form
                    Container(
                      child: Column(
                        children: [
                          // EMAIL (editable)
                          TextFormField(
                            initialValue: myGlobal_userEmail,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(CupertinoIcons.mail),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                myGlobal_userEmail = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // PHONE (editable)
                          TextFormField(
                            initialValue: myGlobal_userPhone,
                            decoration: InputDecoration(
                              labelText: "Phone",
                              prefixIcon: Icon(CupertinoIcons.phone),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                myGlobal_userPhone = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
