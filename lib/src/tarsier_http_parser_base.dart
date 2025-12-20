import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:tarsier_http_parser/src/response_parser.dart';
import 'package:tarsier_http_parser/src/result.dart';

/// A robust, type-safe HTTP client for making API requests with automatic retry logic.
///
/// This client provides:
/// - Type-safe response parsing using the provided `fromJson` function
/// - Automatic retry logic with exponential backoff (configurable)
/// - Comprehensive error handling with detailed error messages
/// - Support for all common HTTP methods (GET, POST, PUT, PATCH, DELETE)
/// - JSON serialization/deserialization built-in
///
/// ## Example Usage
///
/// ```dart
/// // Initialize the client (typically a singleton in your app)
/// final apiClient = TarsierHttpClient();
///
/// // Example 1: Fetch a single user
/// final userResult = await apiClient.get<User>(
///   Uri.parse('https://api.example.com/users/123'),
///   fromJson: (json) => User.fromJson(json),
/// );
///
/// userResult.onSuccess((user) {
///   print('User fetched: ${user.name}');
/// }).onError((error) {
///   print('Error: $error');
/// });
///
/// // Example 2: Create a new post with retry logic
/// final postResult = await apiClient.post<Post>(
///   Uri.parse('https://api.example.com/posts'),
///   body: {'title': 'Hello', 'content': 'World'},
///   fromJson: (json) => Post.fromJson(json),
///   maxRetries: 3, // Custom retry count for this request
/// );
///
/// // Example 3: Fetch a list of items
/// final itemsResult = await apiClient.get<List<Item>>(
///   Uri.parse('https://api.example.com/items'),
///   fromJson: (json) => (json as List).map((e) => Item.fromJson(e)).toList(),
/// );
///
/// // Example 4: Configure default retry behavior
/// final clientWithCustomRetry = TarsierHttpClient(
///   maxRetries: 5,
///   baseDelay: Duration(milliseconds: 500),
/// );
/// ```
class TarsierHttpClient {
  /// The underlying HTTP client used for making requests.
  final http.Client _client;

  /// Maximum number of retry attempts for failed requests.
  final int maxRetries;

  /// Base delay duration for exponential backoff retries.
  final Duration baseDelay;

  /// Maximum delay duration between retries.
  final Duration maxDelay;

  /// Creates a [TarsierHttpClient] with optional retry configuration.
  ///
  /// ## Parameters
  /// - `maxRetries`: Maximum number of retry attempts (default: 3)
  /// - `baseDelay`: Initial delay duration for exponential backoff (default: 500ms)
  /// - `maxDelay`: Maximum delay duration between retries (default: 10 seconds)
  ///
  /// ## Example
  /// ```dart
  /// // Default configuration (3 retries, 500ms base delay)
  /// final defaultClient = TarsierHttpClient();
  ///
  /// // Custom retry configuration
  /// final aggressiveClient = TarsierHttpClient(
  ///   maxRetries: 5,
  ///   baseDelay: Duration(milliseconds: 200),
  /// );
  ///
  /// // No retries
  /// final noRetryClient = TarsierHttpClient(maxRetries: 0);
  /// ```
  TarsierHttpClient({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
  }) : _client = http.Client();

  /// Performs a GET request to the specified [url] with optional [headers].
  ///
  /// Automatically retries failed requests according to the client's configuration.
  ///
  /// ## Parameters
  /// - `url`: The endpoint URL to send the GET request to
  /// - `headers`: Optional HTTP headers to include with the request
  /// - `fromJson`: A function that converts JSON response to type [T]
  /// - `maxRetries`: Optional override for maximum retry attempts (defaults to client's maxRetries)
  /// - `shouldRetry`: Optional function to determine if a request should be retried based on the response or exception
  ///
  /// ## Returns
  /// A `Future<Result<T>>` containing either the parsed response data or an error message.
  ///
  /// ## Example
  /// ```dart
  /// // Fetch a user with automatic retry
  /// final result = await client.get<User>(
  ///   Uri.parse('https://api.example.com/users/1'),
  ///   fromJson: (json) => User.fromJson(json),
  /// );
  ///
  /// // Fetch with custom retry logic
  /// final result2 = await client.get<List<Post>>(
  ///   Uri.parse('https://api.example.com/posts'),
  ///   fromJson: (json) => (json as List).map((e) => Post.fromJson(e)).toList(),
  ///   maxRetries: 5,
  ///   shouldRetry: (response, exception) {
  ///     // Only retry on server errors (5xx) or network exceptions
  ///     return response?.statusCode != null && response.statusCode >= 500;
  ///   },
  /// );
  /// ```
  Future<Result<T>> get<T>(
    Uri url, {
    Map<String, String>? headers,
    required T Function(dynamic) fromJson,
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    return _executeWithRetry(
      () => _client.get(url, headers: headers),
      fromJson,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
    );
  }

  /// Performs a POST request to the specified [url] with optional [headers] and [body].
  ///
  /// The [body] is automatically JSON-encoded if it's not already a string.
  /// Automatically retries failed requests according to the client's configuration.
  ///
  /// ## Parameters
  /// - `url`: The endpoint URL to send the POST request to
  /// - `headers`: Optional HTTP headers (Content-Type defaults to 'application/json')
  /// - `body`: The request body (JSON-serializable object, Map, or String)
  /// - `fromJson`: A function that converts JSON response to type [T]
  /// - `maxRetries`: Optional override for maximum retry attempts
  /// - `shouldRetry`: Optional function to determine if a request should be retried
  ///
  /// ## Example
  /// ```dart
  /// // Create a new user
  /// final result = await client.post<User>(
  ///   Uri.parse('https://api.example.com/users'),
  ///   body: {'name': 'John', 'email': 'john@example.com'},
  ///   fromJson: (json) => User.fromJson(json),
  /// );
  ///
  /// // Create with custom headers and retry logic
  /// final result2 = await client.post<AuthToken>(
  ///   Uri.parse('https://api.example.com/login'),
  ///   headers: {'X-API-Key': 'your-api-key'},
  ///   body: {'username': 'user', 'password': 'pass'},
  ///   fromJson: (json) => AuthToken.fromJson(json),
  ///   shouldRetry: (response, exception) {
  ///     // Don't retry on 401 (Unauthorized) errors
  ///     return response?.statusCode != 401;
  ///   },
  /// );
  /// ```
  Future<Result<T>> post<T>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    required T Function(dynamic) fromJson,
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    return _executeWithRetry(
      () => _client.post(
        url,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null && body is! String ? jsonEncode(body) : body,
      ),
      fromJson,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
    );
  }

  /// Performs a PUT request to the specified [url] with optional [headers] and [body].
  ///
  /// Automatically retries failed requests according to the client's configuration.
  ///
  /// ## Example
  /// ```dart
  /// // Update a user
  /// final result = await client.put<User>(
  ///   Uri.parse('https://api.example.com/users/1'),
  ///   body: {'name': 'Updated Name'},
  ///   fromJson: (json) => User.fromJson(json),
  /// );
  /// ```
  Future<Result<T>> put<T>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    required T Function(dynamic) fromJson,
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    return _executeWithRetry(
      () => _client.put(
        url,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null && body is! String ? jsonEncode(body) : body,
      ),
      fromJson,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
    );
  }

  /// Performs a PATCH request to the specified [url] with optional [headers] and [body].
  ///
  /// Automatically retries failed requests according to the client's configuration.
  ///
  /// ## Example
  /// ```dart
  /// // Partially update a user
  /// final result = await client.patch<User>(
  ///   Uri.parse('https://api.example.com/users/1'),
  ///   body: {'email': 'new@example.com'},
  ///   fromJson: (json) => User.fromJson(json),
  /// );
  /// ```
  Future<Result<T>> patch<T>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    required T Function(dynamic) fromJson,
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    return _executeWithRetry(
      () => _client.patch(
        url,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null && body is! String ? jsonEncode(body) : body,
      ),
      fromJson,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
    );
  }

  /// Performs a DELETE request to the specified [url] with optional [headers].
  ///
  /// Automatically retries failed requests according to the client's configuration.
  ///
  /// ## Example
  /// ```dart
  /// // Delete a user
  /// final result = await client.delete<void>(
  ///   Uri.parse('https://api.example.com/users/1'),
  ///   fromJson: (json) {}, // For void responses
  /// );
  ///
  /// // Delete with response parsing
  /// final result2 = await client.delete<DeletionConfirmation>(
  ///   Uri.parse('https://api.example.com/users/1'),
  ///   fromJson: (json) => DeletionConfirmation.fromJson(json),
  /// );
  /// ```
  Future<Result<T>> delete<T>(
    Uri url, {
    Map<String, String>? headers,
    required T Function(dynamic) fromJson,
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    return _executeWithRetry(
      () => _client.delete(url, headers: headers),
      fromJson,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
    );
  }

  /// Executes an HTTP request with automatic retry logic.
  ///
  /// Implements exponential backoff retry strategy:
  /// - Delay = baseDelay * (2^retryCount) + random jitter
  /// - Maximum delay capped by [maxDelay]
  /// - Random jitter prevents thundering herd problem
  ///
  /// ## Parameters
  /// - `request`: Function that executes the HTTP request
  /// - `fromJson`: Function to parse the JSON response
  /// - `maxRetries`: Maximum number of retry attempts
  /// - `shouldRetry`: Function to determine if a request should be retried
  Future<Result<T>> _executeWithRetry<T>(
    Future<http.Response> Function() request,
    T Function(dynamic) fromJson, {
    int? maxRetries,
    bool Function(http.Response?, Exception?)? shouldRetry,
  }) async {
    final effectiveMaxRetries = maxRetries ?? this.maxRetries;
    final effectiveShouldRetry = shouldRetry ?? _defaultShouldRetry;

    Exception? lastException;
    http.Response? lastResponse;

    for (int attempt = 0; attempt <= effectiveMaxRetries; attempt++) {
      try {
        lastResponse = await request();
        lastException = null;

        // Check if we should retry based on response status
        if (attempt < effectiveMaxRetries && effectiveShouldRetry(lastResponse, null)) {
          await _waitForRetry(attempt);
          continue;
        }

        // Parse the response
        return await ResponseParser.parse<T>(lastResponse, fromJson);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        lastResponse = null;

        // Check if we should retry based on exception
        if (attempt < effectiveMaxRetries && effectiveShouldRetry(null, lastException)) {
          await _waitForRetry(attempt);
          continue;
        }

        return Result.error('Request failed after ${attempt + 1} attempts: $lastException');
      }
    }

    // This should never be reached, but provides a fallback
    return Result.error('Request failed after $effectiveMaxRetries retries');
  }

  /// Default retry predicate function.
  ///
  /// Retries on:
  /// - Server errors (5xx status codes)
  /// - Network exceptions (SocketException, TimeoutException, etc.)
  /// - 408 (Request Timeout)
  /// - 429 (Too Many Requests)
  ///
  /// Does NOT retry on:
  /// - Client errors (4xx, except 408 and 429)
  /// - Successful responses (2xx)
  bool _defaultShouldRetry(http.Response? response, Exception? exception) {
    if (exception != null) {
      // Retry on network exceptions
      return true;
    }

    if (response != null) {
      final statusCode = response.statusCode;
      // Retry on server errors, timeouts, and rate limiting
      return statusCode >= 500 ||
          statusCode == 408 || // Request Timeout
          statusCode == 429; // Too Many Requests
    }

    return false;
  }

  /// Waits for the appropriate delay before retrying.
  ///
  /// Uses exponential backoff with jitter:
  /// delay = min(baseDelay * 2^attempt + random(0, baseDelay), maxDelay)
  Future<void> _waitForRetry(int attempt) async {
    if (attempt <= 0) return;

    final exponentialDelay = baseDelay * pow(2, attempt - 1).toInt();

    // Add jitter (± baseDelay/2) to prevent synchronized retries
    final jitter = Random().nextInt(baseDelay.inMilliseconds ~/ 2);
    final totalDelay = exponentialDelay.inMilliseconds + jitter;

    final delayDuration = Duration(
      milliseconds: min(totalDelay, maxDelay.inMilliseconds),
    );

    await Future.delayed(delayDuration);
  }

  /// Closes the underlying HTTP client and releases resources.
  ///
  /// Call this method when the client is no longer needed,
  /// typically in a dispose() method or when the app is closing.
  ///
  /// ## Example
  /// ```dart
  /// @override
  /// void dispose() {
  ///   apiClient.close();
  ///   super.dispose();
  /// }
  /// ```
  void close() {
    _client.close();
  }
}
