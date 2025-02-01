/// A generic class to encapsulate API responses.
/// It provides factory constructors for success and error cases.
class Result<T> {
  /// The parsed data from the API response.
  final T? data;

  /// An error message in case the request failed.
  final String? errorMessage;

  /// Private constructor to initialize the Result.
  Result._({this.data, this.errorMessage});

  /// Returns `true` if the result represents a successful response.
  bool get isSuccess => data != null;

  /// Returns `true` if the result represents an error response.
  bool get isError => errorMessage != null;

  /// Factory method to create a success result.
  factory Result.success(T data) => Result._(data: data);

  /// Factory method to create an error result.
  factory Result.error(String errorMessage) =>
      Result._(errorMessage: errorMessage);

  /// Executes the [callback] if the result represents a success.
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data as T);
    }
    return this;
  }

  /// Executes the [callback] if the result represents an error.
  Result<T> onError(void Function(String errorMessage) callback) {
    if (isError && errorMessage != null) {
      callback(errorMessage!);
    }
    return this;
  }
}
