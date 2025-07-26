import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model
///
/// Represents teacher profile data including preferences,
/// classes taught, and language settings.
class UserProfile extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String preferredLanguage;
  final List<String> classesTeaching;
  final List<String> subjectsTeaching;
  final String? schoolName;
  final String? location;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    required this.preferredLanguage,
    required this.classesTeaching,
    required this.subjectsTeaching,
    this.schoolName,
    this.location,
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserProfile from Firestore data
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      classesTeaching: List<String>.from(data['classesTeaching'] ?? []),
      subjectsTeaching: List<String>.from(data['subjectsTeaching'] ?? []),
      schoolName: data['schoolName'],
      location: data['location'],
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'preferredLanguage': preferredLanguage,
      'classesTeaching': classesTeaching,
      'subjectsTeaching': subjectsTeaching,
      'schoolName': schoolName,
      'location': location,
      'preferences': preferences,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  /// Copy with updated fields
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? preferredLanguage,
    List<String>? classesTeaching,
    List<String>? subjectsTeaching,
    String? schoolName,
    String? location,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      classesTeaching: classesTeaching ?? this.classesTeaching,
      subjectsTeaching: subjectsTeaching ?? this.subjectsTeaching,
      schoolName: schoolName ?? this.schoolName,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted classes string for display
  String get formattedClasses {
    if (classesTeaching.isEmpty) return 'No classes';
    if (classesTeaching.length == 1) return 'Class ${classesTeaching.first}';

    final sorted = [...classesTeaching]..sort();
    if (sorted.length <= 3) {
      return 'Class ${sorted.join(', ')}';
    }

    return 'Class ${sorted.first}-${sorted.last}';
  }

  /// Get formatted subjects string for display
  String get formattedSubjects {
    if (subjectsTeaching.isEmpty) return 'All subjects';
    if (subjectsTeaching.length <= 2) {
      return subjectsTeaching.join(' & ');
    }
    return '${subjectsTeaching.take(2).join(', ')} +${subjectsTeaching.length - 2}';
  }

  /// Get language display name
  String get languageDisplayName {
    switch (preferredLanguage) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      case 'bn':
        return 'বাংলা';
      case 'gu':
        return 'ગુજરાતી';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'te':
        return 'తెలుగు';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'or':
        return 'ଓଡ଼ିଆ';
      case 'as':
        return 'অসমীয়া';
      default:
        return 'English';
    }
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        phoneNumber,
        preferredLanguage,
        classesTeaching,
        subjectsTeaching,
        schoolName,
        location,
        preferences,
        createdAt,
        updatedAt,
      ];
}
