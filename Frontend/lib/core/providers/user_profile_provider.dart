import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'auth_provider.dart';

/// User profile provider
///
/// Manages user profile data from Firestore and provides
/// reactive updates to the UI components.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return UserProfile.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  });
});

/// User profile service provider
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// User profile service class
///
/// Handles all user profile operations including
/// creation, updates, and data synchronization.
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create or update user profile
  Future<void> createOrUpdateProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Update specific profile fields
  Future<void> updateProfileField(String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(user.uid).update({field: value});
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
