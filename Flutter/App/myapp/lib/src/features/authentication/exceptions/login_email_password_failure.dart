class LoginWithEmailAndPasswordFailure {
  final String message;

  //constructor
  const LoginWithEmailAndPasswordFailure(
      [this.message = "An Unknown error has occurred."]);

  //factory returns instances of code, based on errors and we can switch/catch based on user input
  factory LoginWithEmailAndPasswordFailure.code(String code) {
    switch (code) {
      case 'invalid-email':
        return LoginWithEmailAndPasswordFailure('Email address is invalid.');
      case 'user-disabled':
        return LoginWithEmailAndPasswordFailure('This user has been disabled.');
      case 'user-not-found':
        return LoginWithEmailAndPasswordFailure(
            'No user found for that email.');
      case 'wrong-password':
        return LoginWithEmailAndPasswordFailure('Incorrect password provided.');
      default: //default
        return LoginWithEmailAndPasswordFailure();
    }
  }
}
