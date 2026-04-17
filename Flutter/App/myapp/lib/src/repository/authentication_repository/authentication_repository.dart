import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart' as gis;
import 'package:myapp/src/features/authentication/exceptions/login_email_password_failure.dart';



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
    //ever(firebaseUser, _setInitialScreen);
  }

  /****************** TESTING PURPOSE: SET TO HOMESCREEN **************************/ /**
  _setInitialScreen(User? user) {
    //user is logged out or a new user -> go to welcome screen : otherwise uesr is logged in -> homescreen

    user == null
        ? Get.offAll(() => const WelcomeScreen()) //should be Welcome Screen
        : Get.offAll(() => const HomeScreen());
  } **/

//------------------------GOOGLE SIGN IN -------------------------------*/
//future method to send an async request for GOOGLE
//returns user creds
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. FIX: Capital 'G' for the constructor GoogleSignIn()
      final gis.GoogleSignIn googleSignIn = gis.GoogleSignIn();

      // 2. Show Google popup
      final gis.GoogleSignInAccount? userAccount = await googleSignIn.signIn();

      // If user cancelled, return null
      if (userAccount == null) return null;

      // 3. Get Google authentication
      final gis.GoogleSignInAuthentication googleAuth = await userAccount.authentication;

      // 4. FIX: You were missing the line that actually creates the "credentials" variable
      final OAuthCredential credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credentials);

    } on FirebaseAuthException catch (e) {
      final ex = LoginWithEmailAndPasswordFailure.code(e.code);
      throw ex.message;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      const ex = LoginWithEmailAndPasswordFailure();
      throw ex.message;
    }
  }




}

