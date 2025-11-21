class SignUpWithEmailAndPasswordFailure {
  final String message;

  //constructor
  const SignUpWithEmailAndPasswordFailure([this.message = "An Unknown error has occurred."]);

  //factory returns instances of code, based on errors and we can switch/catch based on user input
  factory SignUpWithEmailAndPasswordFailure.code(String code){

    switch(code){ //switch cases
      case ' ' : return SignUpWithEmailAndPasswordFailure('');
      case 'weak-password': return SignUpWithEmailAndPasswordFailure('Password is too weak, try again');
      default: return SignUpWithEmailAndPasswordFailure(); //default message


    }
  }
}