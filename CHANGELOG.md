## 1.0.0

- Initial release of `TarsierHttpClient`.
- Added `get`, `post`, and `delete` methods for making HTTP requests.
- Implemented dynamic JSON parsing with generic types.
- Included error handling with `Result<T>` to encapsulate success and error states.
- Added `fromJson` function for flexible type conversion.
- Introduced modular design to avoid unnecessary inheritance from `http.Client`.