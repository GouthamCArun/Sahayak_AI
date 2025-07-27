// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/bottom_navigation.dart';
import '../../content_generator/screens/content_generator_screen.dart';
import '../../worksheet_maker/screens/worksheet_maker_screen.dart';
import '../../ask_ai/screens/ask_ai_screen.dart';
import '../../visual_aids/screens/visual_aids_screen.dart';
import '../../reading_assessment/screens/reading_assessment_screen.dart';
import '../../weekly_planner/screens/weekly_planner_screen.dart';
import '../../quiz_generator/screens/quiz_generator_screen.dart';

/// Home screen matching the beautiful UI design
///
/// Displays the main dashboard with 2x3 feature grid, profile header,
/// and bottom navigation as shown in the design mockup.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Profile Header Section
              ProfileHeader(userProfile: userProfile),

              const SizedBox(height: 32),

              // Feature Cards Grid (2x3 layout as in design)
              _buildFeatureGrid(context),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 0,
        onItemSelected: (index) {
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      FeatureCardData(
        title: 'Content\nGenerator',
        color: AppTheme.primaryPink,
        illustration: 'content_generator',
        onTap: () => _navigateToFeature('content_generator'),
      ),
      FeatureCardData(
        title: 'Worksheet\nMaker',
        color: AppTheme.primaryOrange,
        illustration: 'worksheet_maker',
        onTap: () => _navigateToFeature('worksheet_maker'),
      ),
      FeatureCardData(
        title: 'Ask\nSahaayak',
        color: AppTheme.primaryGreen,
        illustration: 'ask_ai',
        isLarge: true, // This card is larger in the design
        onTap: () => _navigateToFeature('ask_ai'),
      ),
      FeatureCardData(
        title: 'Visual Aids',
        subtitle: 'Apch Soosmsnt',
        color: AppTheme.primaryPurple,
        illustration: 'visual_aids',
        onTap: () => _navigateToFeature('visual_aids'),
      ),
      FeatureCardData(
        title: 'Quiz\nGenerator',
        color: AppTheme.primaryBlue,
        illustration: 'quiz_generator',
        onTap: () => _navigateToFeature('quiz_generator'),
      ),
      FeatureCardData(
        title: 'Weekly\nPlanner',
        color: AppTheme.primaryPink,
        illustration: 'weekly_planner',
        onTap: () => _navigateToFeature('weekly_planner'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjusted for the design proportions
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];

        // Special handling for the "Ask Sahaayak" card which spans differently
        if (feature.isLarge && index == 2) {
          return _buildFeatureCard(feature);
        }

        return _buildFeatureCard(feature);
      },
    );
  }

  Widget _buildFeatureCard(FeatureCardData data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: data.color.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForFeature(data.illustration),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (data.isLarge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForFeature(String feature) {
    switch (feature) {
      case 'content_generator':
        return Icons.auto_stories;
      case 'worksheet_maker':
        return Icons.assignment;
      case 'ask_ai':
        return Icons.chat;
      case 'visual_aids':
        return Icons.palette;
      case 'quiz_generator':
        return Icons.quiz;
      case 'weekly_planner':
        return Icons.calendar_today;
      default:
        return Icons.apps;
    }
  }

  void _navigateToFeature(String feature) {
    switch (feature) {
      case 'content_generator':
        Navigator.pushNamed(context, '/content-generator');
        break;
      case 'worksheet_maker':
        Navigator.pushNamed(context, '/worksheet-maker');
        break;
      case 'ask_ai':
        Navigator.pushNamed(context, '/ask-ai');
        break;
      case 'visual_aids':
        Navigator.pushNamed(context, '/visual-aids');
        break;
      case 'quiz_generator':
        Navigator.pushNamed(context, '/quiz-generator');
        break;
      case 'weekly_planner':
        Navigator.pushNamed(context, '/weekly-planner');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$feature coming soon!'),
            backgroundColor: AppTheme.primaryOrange,
          ),
        );
    }
  }

  void _handleBottomNavigation(int index) {
    // Handle navigation based on index
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        Navigator.pushNamed(context, '/content-generator');
        break;
      case 2:
        // Center action button - show quick actions
        break;
      case 3:
        Navigator.pushNamed(context, '/ask-ai');
        break;
      case 4:
        Navigator.pushNamed(context, '/weekly-planner');
        break;
    }
  }

  void _navigateToProfile() {
    // TODO: Navigate to profile screen
  }

  void _navigateToSearch() {
    // TODO: Navigate to search screen
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings screen
  }
}

/// Data model for feature cards
class FeatureCardData {
  final String title;
  final String? subtitle;
  final Color color;
  final String illustration;
  final bool isLarge;
  final VoidCallback onTap;

  const FeatureCardData({
    required this.title,
    this.subtitle,
    required this.color,
    required this.illustration,
    this.isLarge = false,
    required this.onTap,
  });
}
