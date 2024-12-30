import 'dart:convert';
import 'package:http/http.dart';
import 'package:tarsier_http_parser/src/result.dart';

/// Utility class to parse API responses and handle error or success states.
class ResponseParser {
  /// Parses the HTTP [response] into a [Result] object.
  ///
  /// The [fromJsonT] function is used to transform the parsed JSON
  /// into the required data type [T].
  ///
  /// Example usage:
  /// ```dart
  /// final result = await ResponseParser.parse<User>(
  ///   response,
  ///   (json) => User.fromJson(json),
  /// );
  /// result
  ///   .onSuccess((user) => print(user))
  ///   .onError((error) => print('Error: $error'));
  /// ```
  static Future<Result<T>> parse<T>(
    Response response,
    T Function(dynamic) fromJsonT,
  ) async {
    try {
      // Parse the response body as JSON.
      final dynamic json = jsonDecode(response.body);

      // Handle error or success responses based on HTTP status code and API message.
      if (response.statusCode == 200) {
        final T data = fromJsonT(json);
        return Result.success(data);
      } else {
        final message = _extractErrorMessage(response, json);
        final String errorMessage =
            buildResponseErrors(response, errorMessage: message);
        return Result.error(errorMessage);
      }
    } catch (e) {
      // Catch and handle any unexpected parsing errors.
      return Result.error('Unexpected error: ${e.toString()}');
    }
  }

  /// Extracts an error message from the response, if available.
  ///
  /// If the API provides a specific error message field, it can be customized here.
  static String _extractErrorMessage(Response response, dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey('message')) {
      return json['message'] as String;
    }
    return 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
  }

  /// Processes HTTP response errors and generates a formatted error message.
  ///
  /// This function:
  /// - Checks if the [response] status code is not 200 (indicating an error).
  /// - Decodes the [response] body and examines the `errors` field to build a detailed error message.
  /// - Handles cases where `errors` can either be a map (object) or a list of errors.
  /// - Appends each error to the [errorMessage] string, separating them by new lines.
  /// - It reconstruct the error response because the response is not consistent on returning
  ///   data such list [] and object {}
  ///
  /// Parameters:
  /// - [response]: The HTTP response to process.
  /// - [errorMessage]: An optional initial error message string to append additional errors.
  ///
  /// Throws:
  /// - An [Exception] containing the combined [errorMessage] if errors are found.
  ///
  /// Example error format:
  /// ```
  /// {
  ///   "errors": {
  ///     "field1": ["Error message 1", "Error message 2"],
  ///     "field2": ["Error message 3"]
  ///   }
  /// }
  /// ```

  static buildResponseErrors(response, {String errorMessage = ''}) {
    if (response.statusCode != 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body['errors'] != null && body['errors'] is Map<String, dynamic>) {
        // Validate if errors is object {}
        Map<String, dynamic> errors = body['errors'] ?? {};
        errors.forEach((key, value) {
          value.forEach((element) {
            errorMessage += element + '\n';
          });
        });
      } else if (body['errors'] != null && body['errors'] is List<dynamic>) {
        // Validate if errors is list []
        List<dynamic> errors = body['errors'] ?? [];
        for (var element in errors) {
          if (element is Map<String, dynamic>) {
            Map<String, dynamic> errors = element ?? {};
            errors.forEach((key, value) {
              value.forEach((element) {
                errorMessage += element + '\n';
              });
            });
          }
          if (element is String) {
            errorMessage += '$element\n';
          }
        }
      } else {}
    }
    return errorMessage.trim();
  }
}
