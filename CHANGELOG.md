## 1.1.0
- feat: major refactor for multi-type support and retry logic
- feat: implement exponential backoff retry strategy
- feat: enhance ResponseParser with multi-format error handling
- BREAKING CHANGE: new API with method-level type parameters
- docs: comprehensive documentation and examples

- :feat: add custom retry predicate support
- feat: implement HTML error page parsing
- feat: add support for custom success status codes
- feat: add per-request configuration overrides

- fix: resolve void type comparison issue
- fix: improve empty response handling
- perf: optimize retry delay calculations
- refactor: simplify error handling flow

## 1.0.2
- Updated dependency versions to latest stable releases
- Improved Dart 3 analysis and linting configuration
- Bumped compatibility with all Dart 3.x SDKs

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