/// A library to simplify HTTP response parsing and error handling in Dart.
///
/// ## Features:
/// - **Dynamic JSON Parsing**: Convert HTTP response bodies into strongly typed objects.
/// - **Result Wrapper**: Encapsulate success and error states with the `Result<T>` class.
/// - **Error Handling**: Easily handle HTTP errors with consistent messaging.
///
/// ## Getting Started
/// Import this library in your Dart application:
///
/// ```dart
/// import 'package:tarsier_http_parser/tarsier_http_parser.dart';
/// ```
///
/// Use it to parse HTTP responses and handle errors seamlessly.
///
/// ## Example
/// ```dart
/// import 'package:tarsier_http_parser/tarsier_http_parser.dart';
///
/// // Example usage with a User model:
/// final result = await ResponseParser.parse<User>(
///   response,
///   (json) => User.fromJson(json),
/// );
///
/// result
///   .onSuccess((user) => print('User: ${user.name}'))
///   .onError((error) => print('Error: $error'));
/// ```
///
/// For more details, check the documentation of the exported classes and methods.

library tarsier_http_parser;

export 'src/tarsier_http_parser_base.dart';
export 'src/response_parser.dart';
export 'src/result.dart';
