import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// API service for connecting to Sahaayak AI backend
///
/// Handles all HTTP communication between Flutter frontend
/// and FastAPI backend with proper authentication.
class ApiService {
  static late Dio _dio;
  // Android emulator uses 10.0.2.2 to reach host machine
  // iOS simulator can use localhost
  static const String baseUrl = 'http://10.0.2.2:8001/api/v1'; // Flask backend

  /// Initialize the API service
  static Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  /// Get Dio instance
  static Dio get dio => _dio;

  /// Make authenticated request
  static Future<Response> authenticatedRequest(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await _dio.get(path, queryParameters: queryParameters);
        case 'POST':
          return await _dio.post(path,
              data: data, queryParameters: queryParameters);
        case 'PUT':
          return await _dio.put(path,
              data: data, queryParameters: queryParameters);
        case 'DELETE':
          return await _dio.delete(path, queryParameters: queryParameters);
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate content using AI
  static Future<Map<String, dynamic>> generateContent({
    required String contentType,
    required String topic,
    String language = 'en',
    String? gradeLevel,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final response = await authenticatedRequest(
        '/generate', // Updated to match Flask backend endpoint
        method: 'POST',
        data: {
          'type': 'content_generation',
          'content_type': contentType,
          'topic': topic,
          'language': language,
          'grade_level': gradeLevel,
          ...?additionalParams,
        },
      );

      // Debug logging
      print('🔍 API Response received:');
      print('Response type: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('Response keys: ${(response.data as Map).keys.toList()}');
        print(
            'Has generated_text: ${(response.data as Map).containsKey('generated_text')}');
        print('Has content: ${(response.data as Map).containsKey('content')}');
        if ((response.data as Map).containsKey('generated_text')) {
          final text = (response.data as Map)['generated_text'];
          print('Generated text length: ${text?.toString().length ?? 0}');
          final preview = text?.toString().substring(
                  0,
                  text.toString().length > 100
                      ? 100
                      : text.toString().length) ??
              '';
          print('Generated text preview: $preview...');
        }
      }
      print('Full response: ${response.data}');

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Ask AI a question
  static Future<Map<String, dynamic>> askQuestion({
    required String question,
    String language = 'en',
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await authenticatedRequest(
        '/query',
        method: 'POST',
        data: {
          'type': 'question_answering',
          'text': question,
          'language': language,
          'context': context,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate visual aid description
  static Future<Map<String, dynamic>> generateVisualAid({
    required String concept,
    String diagramType = 'simple',
    String language = 'en',
    String gradeLevel = 'grade_3_4',
  }) async {
    try {
      final response = await authenticatedRequest(
        '/visual-aids', // Updated to match Flask backend endpoint
        method: 'POST',
        data: {
          'concept': concept,
          'diagram_type': diagramType,
          'language': language,
          'grade_level': gradeLevel,
        },
      );

      // Debug logging for visual aids
      print('🎨 Visual Aid Response received:');
      print('Response type: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('Response keys: ${(response.data as Map).keys.toList()}');
        print(
            'Has diagram_description: ${(response.data as Map).containsKey('diagram_description')}');
        print(
            'Has ascii_art: ${(response.data as Map).containsKey('ascii_art')}');
        if ((response.data as Map).containsKey('diagram_description')) {
          final desc = (response.data as Map)['diagram_description'];
          print('Diagram description length: ${desc?.toString().length ?? 0}');
        }
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate worksheet from image
  static Future<Map<String, dynamic>> generateWorksheet({
    required String image,
    required List<String> targetGrades,
    String language = 'en',
    String subject = 'general',
  }) async {
    try {
      final response = await _dio.post(
        '/worksheet-adapter',
        data: {
          'image': image,
          'target_grades': targetGrades,
          'language': language,
          'subject': subject,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Assess reading from audio
  static Future<Map<String, dynamic>> assessReading({
    required String audio,
    String? expectedText,
    String gradeLevel = 'grade_3_4',
    String language = 'en',
    String assessmentType = 'reading_fluency',
  }) async {
    try {
      final response = await _dio.post(
        '/assess-reading',
        data: {
          'audio': audio,
          'expected_text': expectedText,
          'grade_level': gradeLevel,
          'language': language,
          'assessment_type': assessmentType,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate lesson plan
  static Future<Map<String, dynamic>> generateLessonPlan({
    required String subject,
    required List<String> gradeLevels,
    String duration = 'week',
    String? topic,
    String language = 'en',
    String resourceLevel = 'basic',
  }) async {
    try {
      final response = await _dio.post(
        '/lesson-plan',
        data: {
          'subject': subject,
          'grade_levels': gradeLevels,
          'duration': duration,
          'topic': topic,
          'language': language,
          'resource_level': resourceLevel,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user interaction history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await authenticatedRequest('/history');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate worksheet from topic
  static Future<Map<String, dynamic>> generateTopicWorksheet({
    required String topic,
    String language = 'en',
    String gradeLevel = 'grade_3_4',
    String subject = 'general',
    String worksheetType = 'mixed',
  }) async {
    try {
      final response = await authenticatedRequest(
        '/worksheet-maker',
        method: 'POST',
        data: {
          'topic': topic,
          'language': language,
          'grade_level': gradeLevel,
          'subject': subject,
          'worksheet_type': worksheetType,
        },
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate quiz from topic
  static Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    String language = 'en',
    String gradeLevel = 'grade_3_4',
    int numQuestions = 10,
  }) async {
    try {
      final response = await authenticatedRequest(
        '/generate-quiz',
        method: 'POST',
        data: {
          'topic': topic,
          'language': language,
          'grade_level': gradeLevel,
          'num_questions': numQuestions,
        },
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  static Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message =
              error.response?.data?['message'] ?? 'Server error occurred';
          return Exception('Server error ($statusCode): $message');
        case DioExceptionType.cancel:
          return Exception('Request was cancelled');
        default:
          return Exception('Network error occurred');
      }
    }
    return Exception('Unexpected error: $error');
  }
}

/// Authentication interceptor to add Firebase ID token to requests
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Continue without auth header if token retrieval fails
    }
    handler.next(options);
  }
}

/// Logging interceptor for debugging
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('📤 Request: ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        '📥 Response: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ Error: ${err.message} ${err.requestOptions.path}');
    handler.next(err);
  }
}
