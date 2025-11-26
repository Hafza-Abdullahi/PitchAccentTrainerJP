import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/src/features/authentication/exceptions/login_email_password_failure.dart';
import 'package:myapp/src/features/authentication/screens/home/home_screen.dart';
import 'package:myapp/src/features/authentication/screens/welcome/welcome_screen.dart';


//firebase class
class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  //private variables
  final _auth = FirebaseAuth.instance;

  //non private vars
  //late var since its not initialised
  late final Rx<User?>
  firebaseUser; //user tracks user state, even when app is closed, can be nullable

  //runs every time on launch
  @override
  void onReady() {
    //init firebaseUser in func
    firebaseUser =
        Rx<User?>(_auth.currentUser); //better format for cast to avoid errors,
    // previous version: "_auth.currentUser as Rx<User?> "
    firebaseUser
        .bindStream(_auth.userChanges()); //userChanges() is always listening

    //ever handles events and is always ready, when called, calls _setInitialScreen
    ever(firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) {
    //user is logged out or a new user -> go to welcome screen : otherwise uesr is logged in -> homescreen
    user == null
        ? Get.offAll(() => const WelcomeScreen())
        : Get.offAll(() => const HomeScreen());
  }

//------------------------GOOGLE SIGN IN -------------------------------*/
//future method to send an async request for GOOGLE
//returns user creds
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Create Google sign-in instance
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Show Google popup
      final GoogleSignInAccount? userAccount = await googleSignIn.signIn();
      if (userAccount == null) return null; // user cancelled

      // Get Google authentication
      final GoogleSignInAuthentication googleAuth = await userAccount.authentication;

      // Create Firebase credential
      final OAuthCredential credentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credentials);

    } on FirebaseAuthException catch (e) {
      final ex = LoginWithEmailAndPasswordFailure.code(e.code);
      throw ex.message;
    } catch (_) {
      const ex = LoginWithEmailAndPasswordFailure();
      throw ex.message;
    }
  }




}

