import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/auth_exception.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Use verifiedAuthStateChanges instead of regular authStateChanges
  Stream<User?> get verifiedAuthStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        // Reload user to get fresh email verification status
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        return refreshedUser?.emailVerified == true ? refreshedUser : null;
      }
      return null;
    });
  }

  // Keep regular authStateChanges for the verification screen
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

  // Enhanced signUp method with better display name handling
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Validate display name
      if (displayName.trim().isEmpty) {
        throw AuthException('invalid-display-name', 'Please enter a display name');
      }
      
      if (displayName.trim().length < 2) {
        throw AuthException('invalid-display-name', 'Display name must be at least 2 characters long');
      }

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name with proper validation
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(displayName.trim());
          await userCredential.user!.reload(); // Reload to get updated profile
          
          // Send verification email
          await userCredential.user!.sendEmailVerification();
          
          return _firebaseAuth.currentUser; // Get the refreshed user
        } catch (e) {
          // If display name update fails, delete the user to maintain consistency
          await userCredential.user!.delete();
          throw AuthException('profile-update-failed', 'Failed to set up user profile. Please try again.');
        }
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _getFriendlyMessage(e));
    } catch (e) {
      throw AuthException('unknown-error', 'An unexpected error occurred: $e');
    }
  }

  // Enhanced signIn method with email verification enforcement
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Enhanced email verification check
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Resend verification email automatically
        await userCredential.user!.sendEmailVerification();
        await _firebaseAuth.signOut();
        throw AuthException(
          'email-not-verified', 
          'Please verify your email before signing in. A new verification email has been sent to ${userCredential.user!.email}'
        );
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
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

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw AuthException('invalid-operation', 'No unverified user found.');
    }
  }

  // Check if user is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  // Enhanced method to get display name with fallbacks
  String get displayName {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Priority: Display Name -> Email username -> Fallback
      return user.displayName?.trim() ?? 
             user.email?.split('@').first.trim() ??
             'Book Lover';
    }
    return 'Unknown User';
  }

  // Method to update display name
  Future<void> updateDisplayName(String newDisplayName) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      if (newDisplayName.trim().isEmpty) {
        throw AuthException('invalid-name', 'Display name cannot be empty');
      }
      if (newDisplayName.trim().length < 2) {
        throw AuthException('invalid-name', 'Display name must be at least 2 characters long');
      }
      
      await user.updateDisplayName(newDisplayName.trim());
      await user.reload(); // Reload to get updated profile
    }
  }
}