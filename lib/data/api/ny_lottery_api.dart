import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Client for the NY Open Data API (Socrata API)
/// Fetches Powerball lottery drawing results
///
/// API Documentation: https://data.ny.gov/resource/d6yy-54nr.json
/// Dataset: Lottery Powerball Winning Numbers: Beginning 2010
///
/// API Response Format:
/// ```json
/// [{
///   "draw_date": "2024-01-01T00:00:00.000",
///   "winning_numbers": "01 02 03 04 05",
///   "multiplier": "2",
///   // ... other fields
/// }]
/// ```
class NYLotteryApi {
  final Dio _dio;
  static const String _baseUrl = 'https://data.ny.gov/resource/d6yy-54nr.json';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  NYLotteryApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) => debugPrint('[NYLotteryApi] $log'),
      ));
    }
  }

  /// Fetch all drawings (use with caution - can be large dataset)
  /// Returns raw API response data
  /// Consider using pagination or date filters for better performance
  Future<List<dynamic>> fetchAllDrawings() async {
    return _executeWithRetry(() async {
      final response = await _dio.get('');
      final data = response.data as List<dynamic>;
      if (!validateResponse(data)) {
        throw ApiException(
          'Invalid API response format',
          response.statusCode,
          ApiExceptionType.unknown,
        );
      }
      return data;
    });
  }

  /// Fetch drawings since a specific date
  /// Returns drawings from sinceDate to present, ordered by date ascending
  Future<List<dynamic>> fetchDrawingsSince(DateTime sinceDate) async {
    return _executeWithRetry(() async {
      final dateStr = _formatDate(sinceDate);
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$where': 'draw_date >= "$dateStr"',
          '\$order': 'draw_date ASC',
          '\$limit': 50000, // Safety limit
        },
      );
      final data = response.data as List<dynamic>;
      if (!validateResponse(data)) {
        throw ApiException(
          'Invalid API response format',
          response.statusCode,
          ApiExceptionType.unknown,
        );
      }
      return data;
    });
  }

  /// Fetch drawings within a date range
  /// Returns drawings between startDate and endDate (inclusive)
  Future<List<dynamic>> fetchDrawingsBetween(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _executeWithRetry(() async {
      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$where': 'draw_date >= "$startStr" AND draw_date <= "$endStr"',
          '\$order': 'draw_date ASC',
          '\$limit': 50000, // Safety limit
        },
      );
      final data = response.data as List<dynamic>;
      if (!validateResponse(data)) {
        throw ApiException(
          'Invalid API response format',
          response.statusCode,
          ApiExceptionType.unknown,
        );
      }
      return data;
    });
  }

  /// Fetch latest N drawings
  /// Returns most recent drawings, ordered by date descending
  Future<List<dynamic>> fetchLatestDrawings(int limit) async {
    return _executeWithRetry(() async {
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$order': 'draw_date DESC',
          '\$limit': limit,
        },
      );
      final data = response.data as List<dynamic>;
      if (!validateResponse(data)) {
        throw ApiException(
          'Invalid API response format',
          response.statusCode,
          ApiExceptionType.unknown,
        );
      }
      return data;
    });
  }

  /// Format DateTime to YYYY-MM-DD for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check API health by fetching a single record
  /// Returns true if API is reachable and responding
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'\$limit': 1},
      );
      return response.statusCode == 200 && response.data is List;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NYLotteryApi] Health check failed: $e');
      }
      return false;
    }
  }

  /// Validate API response structure
  /// Returns true if response has expected fields
  bool validateResponse(List<dynamic> data) {
    if (data.isEmpty) return true; // Empty is valid

    final first = data.first;
    if (first is! Map<String, dynamic>) return false;

    // Check for required fields
    return first.containsKey('draw_date');
  }

  /// Get total count of available drawings (without fetching all data)
  Future<int> getDrawingCount() async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$select': 'count(*)',
        },
      );
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        final countData = data.first as Map<String, dynamic>;
        return int.parse(countData['count'].toString());
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException._fromDioException(e);
    }
  }

  /// Execute request with retry logic for transient failures
  Future<T> _executeWithRetry<T>(
    Future<T> Function() request, {
    int retries = _maxRetries,
  }) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;

        // Only retry on network/timeout errors
        final shouldRetry = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (!shouldRetry || attempt >= retries) {
          throw ApiException._fromDioException(e);
        }

        if (kDebugMode) {
          debugPrint('[NYLotteryApi] Retry attempt $attempt/$retries after error: ${e.type}');
        }

        await Future.delayed(_retryDelay * attempt); // Exponential backoff
      }
    }
    throw ApiException(
      'Max retries exceeded',
      null,
      ApiExceptionType.unknown,
    );
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  ApiException(this.message, this.statusCode, this.type);

  factory ApiException._fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection.',
          null,
          ApiExceptionType.timeout,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          'Server error: ${e.response?.statusCode}',
          e.response?.statusCode,
          ApiExceptionType.serverError,
        );
      case DioExceptionType.cancel:
        return ApiException(
          'Request cancelled',
          null,
          ApiExceptionType.cancelled,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'No internet connection',
          null,
          ApiExceptionType.network,
        );
      default:
        return ApiException(
          'Unknown error: ${e.message}',
          null,
          ApiExceptionType.unknown,
        );
    }
  }

  @override
  String toString() => 'ApiException: $message';
}

/// Types of API exceptions
enum ApiExceptionType {
  timeout,
  serverError,
  cancelled,
  network,
  unknown,
}
