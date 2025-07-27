import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authentication state provider with mock support
final authStateProvider = StreamProvider<User?>((ref) {
  // For development/testing - use mock authentication
  const bool useMockAuth = true; // Set to false when Firebase is configured

  if (useMockAuth) {
    // Return a stream that simulates logged in state
    return Stream.value(_createMockUser());
  }

  return FirebaseAuth.instance.authStateChanges();
});

/// Create a mock user for testing (using Firebase's current user if available)
User? _createMockUser() {
  // Try to use Firebase's current user if it exists, otherwise return null
  // This allows the app to work in mock mode without Firebase
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (e) {
    // If Firebase fails, we'll handle this in the AuthService
    return null;
  }
}

/// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Authentication service class
///
/// Handles all authentication operations including
/// sign in, sign up, and sign out functionality.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const bool useMockAuth =
      true; // Set to false when Firebase is configured
  static bool _isMockUserLoggedIn = false;

  /// Get current user
  User? get currentUser {
    if (useMockAuth) {
      return _isMockUserLoggedIn ? _createMockUser() : null;
    }
    return _auth.currentUser;
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (useMockAuth) {
      // Mock authentication for demo
      if (email == 'teacher@demo.com' && password == 'demo123') {
        _isMockUserLoggedIn = true;
        // Trigger a state change by creating a new stream
        return null; // Mock success
      } else {
        throw Exception(
            'Invalid demo credentials. Use teacher@demo.com / demo123');
      }
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (useMockAuth) {
      // Mock signup - just return success
      _isMockUserLoggedIn = true;
      return null;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (useMockAuth) {
      _isMockUserLoggedIn = false;
      return;
    }

    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
