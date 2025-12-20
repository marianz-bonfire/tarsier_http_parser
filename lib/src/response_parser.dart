import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tarsier_http_parser/src/result.dart';

/// A comprehensive HTTP response parser for handling API responses with robust error processing.
///
/// This utility class provides methods to parse HTTP responses into typed [Result] objects,
/// extract meaningful error messages from various response formats (JSON, HTML, plain text),
/// and handle API error responses consistently across an application.
///
/// ## Features
/// - Parses successful responses into typed objects using provided `fromJson` functions
/// - Extracts detailed error messages from JSON error responses with multiple formats
/// - Handles HTML error pages by extracting title and message content
/// - Supports various error response formats commonly used by REST APIs
/// - Provides consistent error formatting for better user experience
///
/// ## Common Error Response Formats Supported
///
/// 1. **Simple message format**:
///    ```json
///    {"message": "Invalid credentials"}
///    ```
///
/// 2. **Errors object with field-specific messages**:
///    ```json
///    {
///      "errors": {
///        "email": ["Email is required", "Email format is invalid"],
///        "password": ["Password must be at least 8 characters"]
///      }
///    }
///    ```
///
/// 3. **Errors as array of messages**:
///    ```json
///    {
///      "errors": ["Session expired", "Please login again"]
///    }
///    ```
///
/// 4. **Mixed format with both message and errors**:
///    ```json
///    {
///      "message": "Validation failed",
///      "errors": { "field": ["error"] }
///    }
///    ```
///
/// ## Example Usage
///
/// ```dart
/// // Basic usage with User model
/// final result = await ResponseParser.parse<User>(
///   response,
///   (json) => User.fromJson(json),
/// );
///
/// // Handle the result
/// result
///   .onSuccess((user) => print('User: ${user.name}'))
///   .onError((error) => print('Error: $error'));
///
/// // Parsing a list of items
/// final itemsResult = await ResponseParser.parse<List<Item>>(
///   response,
///   (json) => (json as List).map((e) => Item.fromJson(e)).toList(),
/// );
///
/// // Parsing with custom success status codes
/// final customResult = await ResponseParser.parseWithStatus<AuthToken>(
///   response,
///   (json) => AuthToken.fromJson(json),
///   successStatusCodes: [200, 201], // Accept both 200 and 201 as success
/// );
/// ```
class ResponseParser {
  /// Parses an HTTP [response] into a [Result] object.
  ///
  /// This is the main parsing method that handles both successful responses
  /// (HTTP 200) and error responses, converting them into a typed [Result<T>].
  ///
  /// ## Parameters
  /// - `response`: The HTTP response to parse
  /// - `fromJsonT`: A function that converts JSON data into type [T]
  ///
  /// ## Returns
  /// A `Future<Result<T>>` containing either the parsed data or an error message.
  ///
  /// ## Throws
  /// This method does not throw exceptions. All errors are captured in the returned [Result.error].
  ///
  /// ## Example
  /// ```dart
  /// // Make an HTTP request
  /// final response = await http.get(url);
  ///
  /// // Parse the response
  /// final result = await ResponseParser.parse<User>(
  ///   response,
  ///   (json) => User.fromJson(json),
  /// );
  ///
  /// // Use the result
  /// if (result.isSuccess) {
  ///   final user = result.value;
  ///   print('Welcome ${user.name}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  static Future<Result<T>> parse<T>(
    http.Response response,
    T Function(dynamic) fromJsonT,
  ) async {
    return _parseWithStatusCodes<T>(
      response,
      fromJsonT,
      successStatusCodes: [200],
    );
  }

  /// Parses an HTTP [response] into a [Result] object with customizable success status codes.
  ///
  /// Some APIs may use different HTTP status codes for success (e.g., 201 for created,
  /// 204 for no content). This method allows specifying which status codes should be
  /// treated as successful responses.
  ///
  /// ## Parameters
  /// - `response`: The HTTP response to parse
  /// - `fromJsonT`: A function that converts JSON data into type [T]
  /// - `successStatusCodes`: List of HTTP status codes to treat as successful (default: `[200]`)
  ///
  /// ## Returns
  /// A `Future<Result<T>>` containing either the parsed data or an error message.
  ///
  /// ## Example
  /// ```dart
  /// // Parse a response where 201 (Created) is also considered success
  /// final result = await ResponseParser.parseWithStatus<Post>(
  ///   response,
  ///   (json) => Post.fromJson(json),
  ///   successStatusCodes: [200, 201],
  /// );
  ///
  /// // Handle 204 No Content responses
  /// final deleteResult = await ResponseParser.parseWithStatus<void>(
  ///   response,
  ///   (json) {}, // Empty parser for void responses
  ///   successStatusCodes: [200, 204],
  /// );
  /// ```
  static Future<Result<T>> parseWithStatus<T>(
    http.Response response,
    T Function(dynamic) fromJsonT, {
    List<int> successStatusCodes = const [200],
  }) async {
    return _parseWithStatusCodes<T>(
      response,
      fromJsonT,
      successStatusCodes: successStatusCodes,
    );
  }

  /// Internal method to parse response with customizable success status codes.
  static Future<Result<T>> _parseWithStatusCodes<T>(
    http.Response response,
    T Function(dynamic) fromJsonT, {
    required List<int> successStatusCodes,
  }) async {
    dynamic bodyJson;
    final isJsonResponse = _isJsonContentType(response.headers['content-type']);

    // Attempt to parse JSON only if it appears to be a JSON response
    if (isJsonResponse && response.body.isNotEmpty) {
      try {
        bodyJson = jsonDecode(response.body);
      } catch (e) {
        // If JSON parsing fails but we expected JSON, include this in the error
        if (successStatusCodes.contains(response.statusCode)) {
          return Result.error('Failed to parse JSON response: $e');
        }
        // For error responses, we'll try other parsing methods
        bodyJson = null;
      }
    }

    // Check if this is an error response (not in success status codes)
    if (!successStatusCodes.contains(response.statusCode)) {
      return _handleErrorResponse(response, bodyJson);
    }

    // Handle successful response
    return _handleSuccessResponse(response, bodyJson, fromJsonT);
  }

  /// Handles error responses and extracts meaningful error messages.
  static Result<T> _handleErrorResponse<T>(
    http.Response response,
    dynamic bodyJson,
  ) {
    String errorMessage = '';

    // First, try to extract structured error information from JSON
    if (bodyJson != null) {
      errorMessage = _extractStructuredErrorMessage(response, bodyJson);
    }

    // If no structured error found, try to parse HTML error pages
    if (errorMessage.isEmpty && _isHtmlContentType(response.headers['content-type'])) {
      errorMessage = _parseHtmlErrorPage(response.statusCode, response.body);
    }

    // Fallback to basic error information
    if (errorMessage.isEmpty) {
      errorMessage = _createBasicErrorMessage(response);
    }

    return Result.error(errorMessage);
  }

  /// Handles successful responses and parses the data.
  /// Handles successful responses and parses the data.
  static Result<T> _handleSuccessResponse<T>(
    http.Response response,
    dynamic bodyJson,
    T Function(dynamic) fromJsonT,
  ) {
    // Handle 204 No Content and other empty responses
    if (response.statusCode == 204 || (bodyJson == null && response.body.isEmpty)) {
      // For responses that don't expect data, we need to handle them specially
      // We can't check T == void at runtime, so we'll check if the type is void
      // by trying to create a null result and see if it's valid
      try {
        // Attempt to return success with null
        // This will work for nullable types and void/dynamic
        return Result.success(null as T);
      } catch (e) {
        // If null can't be cast to T, return an error
        return Result.error('Empty response body for type $T which doesn\'t accept null');
      }
    }

    // Parse the JSON data
    if (bodyJson != null) {
      try {
        final T data = fromJsonT(bodyJson);
        return Result.success(data);
      } catch (e) {
        return Result.error('Failed to convert JSON to type $T: $e');
      }
    }

    // If body is empty or not JSON for a successful response
    return Result.error('Empty or non-JSON response for HTTP ${response.statusCode}');
  }

  /// Extracts structured error messages from JSON error responses.
  ///
  /// Supports multiple common error response formats:
  /// 1. Top-level "message" field
  /// 2. Nested "errors" object with field-specific messages
  /// 3. Array of error messages
  /// 4. Mixed formats with both message and errors
  ///
  /// ## Example Formats Handled
  ///
  /// ```json
  /// // Format 1: Simple message
  /// {"message": "Authentication failed"}
  ///
  /// // Format 2: Field-specific errors
  /// {
  ///   "errors": {
  ///     "email": ["Invalid email format"],
  ///     "password": ["Too short", "Missing uppercase"]
  ///   }
  /// }
  ///
  /// // Format 3: Array of errors
  /// {"errors": ["Error 1", "Error 2"]}
  ///
  /// // Format 4: Mixed format
  /// {
  ///   "message": "Validation failed",
  ///   "errors": {"field": ["error"]}
  /// }
  /// ```
  static String _extractStructuredErrorMessage(
    http.Response response,
    dynamic bodyJson,
  ) {
    final buffer = StringBuffer();

    if (bodyJson is Map<String, dynamic>) {
      // Check for top-level message
      if (bodyJson['message'] is String) {
        buffer.writeln(bodyJson['message']);
      }

      // Check for detailed errors structure
      if (bodyJson['errors'] != null) {
        final errors = bodyJson['errors'];
        buffer.write(_parseErrorsObject(errors));
      }

      // Check for error (singular) field
      if (bodyJson['error'] is String) {
        buffer.writeln(bodyJson['error']);
      }
    } else if (bodyJson is String) {
      // Handle plain string error responses
      buffer.writeln(bodyJson);
    }

    final result = buffer.toString().trim();
    if (result.isNotEmpty) {
      return result;
    }

    // Fallback to generic error if no structured message found
    return 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
  }

  /// Parses various error object formats into a readable string.
  ///
  /// Handles multiple formats:
  /// - `Map<String, List<String>>` (field: [errors])
  /// - `Map<String, String>` (field: error)
  /// - `List<String>` (array of errors)
  /// - `List<Map>` (array of error objects)
  /// - Simple string error
  static String _parseErrorsObject(dynamic errors) {
    final buffer = StringBuffer();

    if (errors is Map<String, dynamic>) {
      // Format: {"field": ["error1", "error2"]} or {"field": "error"}
      errors.forEach((field, errorList) {
        if (errorList is List) {
          for (final error in errorList) {
            buffer.writeln('• ${_capitalize(field)}: $error');
          }
        } else if (errorList is String) {
          buffer.writeln('• ${_capitalize(field)}: $errorList');
        }
      });
    } else if (errors is List) {
      // Format: ["error1", "error2"] or [{"field": "error"}]
      for (final error in errors) {
        if (error is String) {
          buffer.writeln('• $error');
        } else if (error is Map<String, dynamic>) {
          buffer.write(_parseErrorsObject(error));
        }
      }
    } else if (errors is String) {
      // Format: "error message"
      buffer.writeln('• $errors');
    }

    return buffer.toString();
  }

  /// Parses HTML error pages and extracts meaningful content.
  ///
  /// Extracts content from:
  /// 1. `<title>` tags for error titles
  /// 2. `<h1>`, `<h2>`, `<h3>` tags for headings
  /// 3. `<p>` tags for detailed messages
  /// 4. `<div class="error">`, `<div class="message">` for common error containers
  static String _parseHtmlErrorPage(int statusCode, String htmlBody) {
    final title = _extractHtmlTagContent(htmlBody, 'title') ?? 'Error';
    final heading = _extractHtmlTagContent(htmlBody, 'h1') ??
        _extractHtmlTagContent(htmlBody, 'h2') ??
        _extractHtmlTagContent(htmlBody, 'h3');

    // Try to extract from common error containers
    final errorContent = _extractHtmlClassContent(htmlBody, ['error', 'message', 'alert', 'exception']);

    // Build the error message
    final buffer = StringBuffer();

    if (heading != null && heading != title) {
      buffer.write('$heading: ');
    } else {
      buffer.write('$title: ');
    }

    if (errorContent != null) {
      buffer.write(errorContent);
    } else {
      // Fallback to first paragraph
      final paragraph = _extractHtmlTagContent(htmlBody, 'p');
      if (paragraph != null && paragraph.length < 500) {
        // Avoid huge HTML dumps
        buffer.write(paragraph);
      } else {
        buffer.write('HTTP $statusCode error');
      }
    }

    return buffer.toString().trim();
  }

  /// Extracts content from an HTML tag using regex.
  static String? _extractHtmlTagContent(String html, String tag) {
    final regex = RegExp(
      '<$tag[^>]*>(.*?)</$tag>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = regex.firstMatch(html);
    if (match != null) {
      final content = match.group(1)?.trim();
      return _stripHtmlTags(content ?? '');
    }
    return null;
  }

  /// Extracts content from HTML elements with specific class names.
  static String? _extractHtmlClassContent(String html, List<String> classNames) {
    for (final className in classNames) {
      final regex = RegExp(
        '<[^>]*class="[^"]*$className[^"]*"[^>]*>(.*?)</[^>]*>',
        caseSensitive: false,
        dotAll: true,
      );
      final match = regex.firstMatch(html);
      if (match != null) {
        final content = match.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          return _stripHtmlTags(content);
        }
      }
    }
    return null;
  }

  /// Strips HTML tags from a string.
  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp('<[^>]*>'), '').trim();
  }

  /// Creates a basic error message from HTTP response.
  static String _createBasicErrorMessage(http.Response response) {
    final buffer = StringBuffer();
    buffer.write('HTTP ${response.statusCode}');

    if (response.reasonPhrase != null && response.reasonPhrase!.isNotEmpty) {
      buffer.write(' (${response.reasonPhrase})');
    }

    // Include first 200 characters of body for context (if not too large)
    if (response.body.isNotEmpty && response.body.length < 10000) {
      final preview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
      buffer.write('\nResponse: $preview');
    }

    return buffer.toString();
  }

  /// Helper method to capitalize a string (first letter uppercase).
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Checks if content type indicates JSON response.
  static bool _isJsonContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.contains('application/json') ||
        contentType.contains('text/json') ||
        contentType.contains('+json');
  }

  /// Checks if content type indicates HTML response.
  static bool _isHtmlContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.contains('text/html');
  }

  /// Standalone method to parse error responses for manual error handling.
  ///
  /// Useful when you need to parse error responses separately from the main flow.
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final response = await http.get(url);
  ///   if (response.statusCode != 200) {
  ///     final errorMessage = ResponseParser.parseErrorResponse(response);
  ///     showErrorDialog(errorMessage);
  ///   }
  /// } catch (e) {
  ///   // Handle other errors
  /// }
  /// ```
  static String parseErrorResponse(http.Response response) {
    dynamic bodyJson;

    // Try to parse JSON
    if (response.body.isNotEmpty) {
      try {
        bodyJson = jsonDecode(response.body);
      } catch (_) {
        bodyJson = null;
      }
    }

    return _extractStructuredErrorMessage(response, bodyJson);
  }
}
