import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/src/features/authentication/exceptions/login_email_password_failure.dart';
import 'package:myapp/src/features/authentication/exceptions/signup_email_password_failure.dart';
import 'package:myapp/src/features/authentication/screens/home/home_screen.dart';
import 'package:myapp/src/features/authentication/screens/welcome/welcome_screen.dart';

import '../../common_widgets/navigation_menu.dart';

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
        : Get.offAll(() => const NavigationMenu());
  }

//------------------------SIGN UP-------------------------------*/
  //future method to send an async request to login
  Future<void> createUserWithEmailAndPassword(String email,
      String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      //if successful go to home screen, otherwise welcomeScreen
      firebaseUser.value != null
          ? Get.offAll(() => const NavigationMenu())
          : Get.to(() => WelcomeScreen());
    } on FirebaseAuthException catch (e) {
      final exception = SignUpWithEmailAndPasswordFailure.code(e.code);
      print('FIREBASE AUTH EXCEPTION - ${exception.message}');
      throw exception;
    } catch (_) {
      //default
      const exception = SignUpWithEmailAndPasswordFailure();
      print('EXCEPTION - ${exception.message}');
    }
  }

  //store data
  //final newSchoolUser = UserModel()

//------------------------Login-------------------------------*/
  //future method to send an async request for login
  Future<String?> loginWithEmailAndPassword(String email,
      String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      final ex = LoginWithEmailAndPasswordFailure.code(e.code);
      return ex.message;
    } catch (_) {
      const ex = LoginWithEmailAndPasswordFailure();
      return ex.message;
    }
    return null;
  }

//------------------------Log Out-------------------------------*/
  Future<void> logout() async => await _auth.signOut();


//------------------------GOOGLE SIGN IN -------------------------------*/
//future method to send an async request for GOOGLE
//returns user creds
  Future<UserCredential?> signInWithGoogle() async {
    try {
      //google sign in
      final GoogleSignInAccount? userAccount = await GoogleSignIn()
          .signIn(); //await google sing in

      //get Oauth details, Oauth is a secure auth protocol that uses third party services
      //aka google, to let users sign in, redirect the user to google login, grant perisiion to share email/info
      //sends a secure token to this app to finalise and confirm user details
      final GoogleSignInAuthentication? googleAuth = await userAccount
          ?.authentication;

      //firebase new credential
      final credentials = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken
      );

      //pass credentials and return using await func
      return await _auth.signInWithCredential(credentials);

    } on FirebaseAuthException catch (e) {
      final ex = LoginWithEmailAndPasswordFailure.code(e.code);
      throw ex.message;
    } catch (_) {
      const ex = LoginWithEmailAndPasswordFailure();
      throw ex.message;
    }
    return null;
  }
}

