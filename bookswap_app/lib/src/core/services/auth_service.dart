import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/auth_exception.dart';

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
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
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
        email: email.trim(),
        password: password,
      );
      
      // Update display name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.sendEmailVerification();
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _getFriendlyMessage(e));
    } catch (e) {
      throw AuthException('unknown-error', 'An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await _firebaseAuth.signOut();
        throw AuthException('email-not-verified', 'Please verify your email before signing in.');
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Provide more specific error messages
      String friendlyMessage = _getFriendlyMessage(e);
      
      // For invalid login, be more generic for security
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        friendlyMessage = 'Invalid email or password. Please try again.';
      }
      
      throw AuthException(e.code, friendlyMessage);
    } catch (e) {
      throw AuthException('unknown-error', 'Failed to sign in. Please try again.');
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