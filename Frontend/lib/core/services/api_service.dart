import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// API service for connecting to Sahaayak AI backend
///
/// Handles all HTTP communication between Flutter frontend
/// and FastAPI backend with proper authentication.
class ApiService {
  static late Dio _dio;
  static const String baseUrl =
      'http://localhost:8000/api/v1'; // Update for production

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
        '/query',
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
    String diagramType = 'auto',
    String language = 'en',
    String gradeLevel = 'grade_3_4',
    String subject = 'general',
  }) async {
    try {
      final response = await _dio.post(
        '/v1/generate-diagram',
        data: {
          'concept': concept,
          'diagram_type': diagramType,
          'language': language,
          'grade_level': gradeLevel,
          'subject': subject,
        },
      );
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
        '/v1/worksheet-adapter',
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
        '/v1/assess-audio',
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
        '/v1/lesson-plan',
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
