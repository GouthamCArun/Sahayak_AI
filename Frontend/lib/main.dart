import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/config/firebase_options.dart';
import 'core/services/api_service.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/content_generator/screens/content_generator_screen.dart';
import 'features/worksheet_maker/screens/worksheet_maker_screen.dart';
import 'features/ask_ai/screens/ask_ai_screen.dart';
import 'features/visual_aids/screens/visual_aids_screen.dart';
import 'features/reading_assessment/screens/reading_assessment_screen.dart';
import 'features/weekly_planner/screens/weekly_planner_screen.dart';
import 'features/quiz_generator/screens/quiz_generator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize API Service
  ApiService.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: SahaayakAIApp()));
}

class SahaayakAIApp extends ConsumerWidget {
  const SahaayakAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sahaayak AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/content-generator': (context) => const ContentGeneratorScreen(),
        '/worksheet-maker': (context) => const WorksheetMakerScreen(),
        '/ask-ai': (context) => const AskAIScreen(),
        '/visual-aids': (context) => const VisualAidsScreen(),
        '/reading-assessment': (context) => const ReadingAssessmentScreen(),
        '/quiz-generator': (context) => const QuizGeneratorScreen(),
        '/weekly-planner': (context) => const WeeklyPlannerScreen(),
      },
    );
  }
}
