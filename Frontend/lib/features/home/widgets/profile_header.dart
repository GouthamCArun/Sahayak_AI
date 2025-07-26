import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Profile header widget matching the UI design
///
/// Displays user information, profile picture, and settings access
/// as shown in the beautiful design mockup.
class ProfileHeader extends StatelessWidget {
  final dynamic userProfile; // Will be properly typed later

  const ProfileHeader({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryBlue,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _buildProfileImage(),
          ),
        ),

        const SizedBox(width: 16),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sahaayak AI',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getUserSubtitle(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Settings/Profile Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _handleProfileTap(context),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    // For now, show a placeholder with initials
    // Later this can load from user profile or show teacher illustration
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryBlue,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  String _getUserSubtitle() {
    // Extract user info from userProfile when available
    // For now, show default text matching the design
    try {
      if (userProfile != null && userProfile.hasData) {
        final profile = userProfile.value;
        final language = profile?['language'] ?? 'Marathi';
        final classes = profile?['classes'] ?? 'Class 1-5';
        return '$language | $classes';
      }
    } catch (e) {
      // Fallback to default
    }

    return 'Marathi | Class 1-5'; // Default as shown in design
  }

  void _handleProfileTap(BuildContext context) {
    // Show profile options or navigate to profile screen
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileBottomSheet(context),
    );
  }

  Widget _buildProfileBottomSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Profile options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileOption(
                  context,
                  'Edit Profile',
                  Icons.edit,
                  AppTheme.primaryPurple,
                  () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                _buildProfileOption(
                  context,
                  'Language Settings',
                  Icons.language,
                  AppTheme.primaryOrange,
                  () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                _buildProfileOption(
                  context,
                  'Help & Support',
                  Icons.help_outline,
                  AppTheme.primaryGreen,
                  () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                _buildProfileOption(
                  context,
                  'Sign Out',
                  Icons.logout,
                  Colors.red,
                  () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
