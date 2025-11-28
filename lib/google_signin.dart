import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSign {
  static bool isInitialized = false;

  Future<void> initialize() async {
    try {
      if (!isInitialized) {
        await GoogleSignIn.instance.initialize(
            serverClientId:
                "625498955166-lq22upmdudsp9ent05rc2ev7hc2smbpo.apps.googleusercontent.com");
      }
      isInitialized = true;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await initialize();

      final GoogleSignInAccount? user = await GoogleSignIn.instance.authenticate();

      if(user == null){
        return;
      }

      final auth = user.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if(!(e.toString().contains('Cancelled by user'))){
        throw Exception(e.toString());
      }
    }
  }
}
