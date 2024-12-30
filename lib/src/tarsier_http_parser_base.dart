import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tarsier_http_parser/src/response_parser.dart';
import 'package:tarsier_http_parser/src/result.dart';

/// A custom HTTP client for making HTTP requests and parsing responses.
class TarsierHttpClient<T> {
  /// The underlying HTTP client used for making requests.
  final http.Client _client;

  /// A function to convert JSON data into a type [T].
  final T Function(dynamic json) fromJson;

  /// Creates a `TarsierHttpClient` with the given [fromJson] function.
  TarsierHttpClient({required this.fromJson}) : _client = http.Client();

  /// Performs a GET request to the given [url] with optional [headers].
  ///
  /// Returns a `Result<T>` with the parsed response or an error message.
  Future<Result<T>> get(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(url, headers: headers);
      return await ResponseParser.parse<T>(response, fromJson);
    } catch (e) {
      return Result.error('Unexpected error during GET: $e');
    }
  }

  /// Performs a POST request to the given [url] with optional [headers] and [body].
  ///
  /// The [body] should be a JSON-serializable object or a string.
  /// Returns a `Result<T>` with the parsed response or an error message.
  Future<Result<T>> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await _client.post(
        url,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return await ResponseParser.parse<T>(response, fromJson);
    } catch (e) {
      return Result.error('Unexpected error during POST: $e');
    }
  }

  /// Performs a DELETE request to the given [url] with optional [headers].
  ///
  /// Returns a `Result<T>` with the parsed response or an error message.
  Future<Result<T>> delete(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.delete(url, headers: headers);
      return await ResponseParser.parse<T>(response, fromJson);
    } catch (e) {
      return Result.error('Unexpected error during DELETE: $e');
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}
