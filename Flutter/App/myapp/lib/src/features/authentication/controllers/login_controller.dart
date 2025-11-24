import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:myapp/src/repository/authentication_repository/authentication_repository.dart';

import '../../../constants/fullscreen_loader.dart';

class LoginController extends GetxController { //getx statemanagement
  //static instance to only use one instance
  static LoginController get instance => Get.find();

  //controllers for input fields
  final localStorage = GetStorage();
  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();


  Future<void> googleSignIn() async {
    try{
      //start loading
      TFullscreenLoader.showLoadingDialogue("text");

      //
      //google auth
      final userCredentials = await AuthenticationRepository.instance.signInWithGoogle();



    }catch(e){
      Get.showSnackbar(GetSnackBar(message: e.toString(),));
    }
  }


}
