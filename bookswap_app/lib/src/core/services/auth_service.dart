import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/auth_exception.dart'; // This import is now used

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  String _getFriendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _getFriendlyMessage(e));
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await signOut();
        throw AuthException('email-not-verified', 'Please verify your email before signing in.');
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _getFriendlyMessage(e));
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if user is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  // Get user display name
  String? get displayName => _firebaseAuth.currentUser?.displayName;
}