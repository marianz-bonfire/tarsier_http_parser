## 1.0.1

* Upgraded environment SDK constraint
+ Added topics and screenshot
+ Added Github workflows
* Fixed issue on reported pub dev analysis warning

## 1.0.0

- Initial release of `TarsierHttpClient`.
- Added `get`, `post`, and `delete` methods for making HTTP requests.
- Implemented dynamic JSON parsing with generic types.
- Included error handling with `Result<T>` to encapsulate success and error states.
- Added `fromJson` function for flexible type conversion.
- Introduced modular design to avoid unnecessary inheritance from `http.Client`.