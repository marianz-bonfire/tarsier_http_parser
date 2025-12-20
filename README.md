<p align="center">
  <a href="https://pub.dev/packages/tarsier_http_parser">
    <img height="260" src="https://raw.githubusercontent.com/marianz-bonfire/tarsier_http_parser/master/assets/logo.png">
  </a>
  <h1 align="center">Tarsier HTTP Parser</h1>
</p>

<p align="center">
  <a href="https://pub.dev/packages/tarsier_http_parser">
    <img src="https://img.shields.io/pub/v/tarsier_http_parser?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://pub.dev/packages/tarsier_http_parser/score">
    <img src="https://img.shields.io/pub/points/tarsier_http_parser?color=2E8B57&label=pub%20points">
  </a>
  <a href="https://github.com/marianz-bonfire/tarsier_http_parser/actions/workflows/dart.yml">
    <img src="https://github.com/marianz-bonfire/tarsier_http_parser/actions/workflows/dart.yml/badge.svg">
  </a>
  <a href="https://tarsier-marianz.blogspot.com">
    <img src="https://img.shields.io/static/v1?label=website&message=tarsier-marianz&labelColor=135d34&logo=blogger&logoColor=white&color=fd3a13">
  </a>
</p>

<p align="center">
  <a href="https://pub.dev/documentation/tarsier_http_parser/latest/">Documentation</a> •
  <a href="https://github.com/marianz-bonfire/tarsier_http_parser/issues">Issues</a> •
  <a href="https://github.com/marianz-bonfire/tarsier_http_parser/tree/master/example">Example</a> •
  <a href="https://github.com/marianz-bonfire/tarsier_http_parser/blob/master/LICENSE">License</a> •
  <a href="https://pub.dev/packages/tarsier_http_parser">Pub.dev</a>
</p>

A lightweight and flexible Dart HTTP client designed for making API calls with dynamic response parsing. It provides an easy way to handle HTTP requests and parse JSON responses into specific data models.


Is a powerful, production-ready HTTP client for Flutter/Dart applications featuring automatic retry logic with exponential backoff and flexible response parsing for multiple data types.

## ✨ Features

- **Simple API**: Includes basic HTTP methods like `GET`, `POST`, and `DELETE`.
- **Dynamic Parsing**: Supports generic types for flexible JSON-to-object conversion.
- **Error Handling**: Encapsulates success and error states using the `Result<T>` class.
- **No Inheritance**: Avoids unnecessary inheritance from `http.Client` for a minimal and focused API.


## 🚀 Key Enhancements (version 1.1.0)

### **1. Dynamic Multi-Type Support (Major Improvement)**
#### **BEFORE:** Type-Locked Client (version 1.0.2)
```dart
// Each data type needed its own client instance
final userClient = TarsierHttpClient<User>(fromJson: User.fromJson);
final postClient = TarsierHttpClient<Post>(fromJson: Post.fromJson);
final roleClient = TarsierHttpClient<Role>(fromJson: Role.fromJson);
// ❌ Multiple instances, memory overhead
// ❌ Can't reuse same client for different endpoints
```
#### **AFTER:*** Single Flexible Client (version 1.1.0)
```dart
// One client handles all data types
final client = TarsierHttpClient();

// Use with ANY type dynamically
final userResult = await client.get<User>(url, fromJson: User.fromJson);
final postResult = await client.get<List<Post>>(url, fromJson: (json) => listFromJson(json));
final roleResult = await client.post<Role>(url, body: data, fromJson: Role.fromJson);
// ✅ Single instance for entire app
// ✅ Clean API with method-level type parameters
// ✅ No client recreation needed
```

### **2. Smart Retry Logic with Exponential Backoff**
```dart
// Configure once, works everywhere
final client = TarsierHttpClient(
  maxRetries: 3,           // Default: 3 retry attempts
  baseDelay: Duration(milliseconds: 500),  // Initial delay
  maxDelay: Duration(seconds: 10),         // Maximum delay cap
);

// Per-request customization
final result = await client.get<User>(
  url,
  fromJson: User.fromJson,
  maxRetries: 5,  // Override for this specific call
  shouldRetry: (response, exception) {
    // Custom retry logic
    return response?.statusCode == 429; // Retry only on rate limits
  },
);
```

### Retry Strategy Features:

- 🔄 Exponential Backoff: Delay = baseDelay × 2^(attempt)
- 🎲 Random Jitter: Prevents synchronized retry storms
- 🎯 Smart Defaults: Retries 5xx errors, timeouts, network issues
- ⚙️ Fully Configurable: Global settings with per-request overrides

## 🚀 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  tarsier_http_parser: ^1.1.0
```
Run the following command:
```bash
flutter pub get
```
## 📒 Usage
- ### Define a Data Model
Create a data model that includes a `fromJson` factory constructor:
```dart
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
```
- ### Initialize the HTTP Client
Create an instance of TarsierHttpClient with the fromJson function for single object:
```dart
import 'package:tarsier_http_parser/tarsier_http_parser.dart';

final apiClient = TarsierHttpClient();
```
- ### Make API Calls
```dart
// Fetch single item
final userResult = await apiClient.get<User>(
  Uri.parse('https://api.example.com/users/1'),
  fromJson: (json) => User.fromJson(json),
);

// Create with automatic JSON encoding
final createResult = await apiClient.post<User>(
  Uri.parse('https://api.example.com/users'),
  body: {'name': 'Jose Rizal', 'email': 'jose@example.com'},
  fromJson: (json) => User.fromJson(json),
);

// Fetch list with retry
final postsResult = await apiClient.get<List<Post>>(
  Uri.parse('https://api.example.com/posts'),
  fromJson: (json) => (json as List).map((e) => Post.fromJson(e)).toList(),
  maxRetries: 3,
);
```

## 🔧 Complete Configuration Guide

Client-Level Settings
```dart
TarsierHttpClient(
  maxRetries: 3,                     // 0 to disable retry
  baseDelay: Duration(milliseconds: 500),  // Initial backoff
  maxDelay: Duration(seconds: 10),   // Maximum wait time
)
```

Per-Request Customization
```dart
await client.get<Data>(
  url,
  // Required: Type conversion function
  fromJson: Data.fromJson,
  
  // Optional: HTTP headers
  headers: {'Authorization': 'Bearer token'},
  
  // Optional: Retry override
  maxRetries: 5,
  
  // Optional: Custom retry condition
  shouldRetry: (response, exception) {
    if (response?.statusCode == 503) return true; // Service unavailable
    if (exception is SocketException) return true; // Network error
    return false;
  },
);
```

Flexible Status Code Support:
```dart
// Custom success status codes
final result = await ResponseParser.parseWithStatus<Post>(
  response,
  (json) => Post.fromJson(json),
  successStatusCodes: [200, 201],  // Accept both 200 and 201
);
```

Supported Error Formats:
```json
// 1. Simple message
{"message": "Authentication failed"}

// 2. Field-specific errors
{
  "errors": {
    "email": ["Invalid email format"],
    "password": ["Too short"]
  }
}

// 3. Array of errors
{"errors": ["Error 1", "Error 2"]}

// 4. Mixed format
{
  "message": "Validation failed",
  "errors": {"field": ["error"]}
}
```

## 📊 Migration Table: Old vs New

| Feature         | Old Version                     | Enhanced Version                                  |
|-----------------|----------------------------------|---------------------------------------------------|
| Type Handling   | One type per client instance     | Multiple types per client                         |
| Retry Logic     | None                             | Automatic with exponential backoff                |
| Error Parsing   | Basic JSON only                  | Multi-format (JSON, HTML, arrays)                 |
| Status Codes    | Hardcoded 200 only               | Configurable success codes                        |
| Memory Usage    | Multiple instances               | Single shared instance                            |
| API Flexibility | Limited                          | Highly flexible                                   |


### 📚 Complete Example Service

```dart
class UserApiService {
  final TarsierHttpClient _client;
  
  UserApiService() : _client = TarsierHttpClient(
    maxRetries: 3,
    baseDelay: Duration(milliseconds: 300),
  );

  Future<User?> getUserById(int id) async {
    final result = await _client.get<User>(
      Uri.parse('https://api.example.com/users/$id'),
      fromJson: (json) => User.fromJson(json),
    );
    
    return result.isSuccess ? result.value : null;
  }

  Future<User> createUser(User user) async {
    final result = await _client.post<User>(
      Uri.parse('https://api.example.com/users'),
      body: user.toJson(),
      fromJson: (json) => User.fromJson(json),
      maxRetries: 2, // Fewer retries for POST
    );
    
    if (result.isError) throw Exception(result.error);
    return result.value;
  }

  Future<List<User>> searchUsers(String query) async {
    final result = await _client.get<List<User>>(
      Uri.parse('https://api.example.com/users?q=$query'),
      fromJson: (json) => (json as List).map((e) => User.fromJson(e)).toList(),
    );
    
    return result.isSuccess ? result.value : [];
  }

  void dispose() {
    _client.close();
  }
}
```

## 🎯 Feature Comparison

| Feature             | TarsierHttpClient        | Standard http package     |
|---------------------|--------------------------|---------------------------|
| Type Safety         | ✅ Full type safety       | ❌ Manual casting         |
| Automatic Retry     | ✅ With backoff           | ❌ Manual implementation |
| Error Parsing       | ✅ Multi-format           | ❌ Basic only             |
| JSON Encoding       | ✅ Automatic              | ❌ Manual required        |
| Single Instance     | ✅ All types              | ❌ N/A                    |
| Custom Retry Logic  | ✅ Per-request            | ❌ Not available          |



### ⚡ Performance Tips

1. Singleton Pattern: Create client once, reuse everywhere
2. Appropriate Retry Counts:
    - `GET`: 3-5 retries (safe to retry)
    - `POST`: 1-2 retries (idempotent operations only)
    - `DELETE/PUT`: 1 retry (can be dangerous)
3. Dispose Properly: Call `close()` when app exits
4. Custom Headers: Set common headers once in a wrapper

### 🆕 What's New Summary
- 🚀 Dynamic Typing - One client for User, Post, Role, any type!
- 🔄 Smart Retry - Automatic recovery from transient failures
- 🎯 Better Errors - Parses JSON arrays, objects, HTML errors
- ⚙️ Flexible Config - Global defaults with per-request overrides
- 🏗️ Production Ready - Timeouts, jitter, edge case handling


## 🎖️ License
This project is licensed under the [MIT License](https://mit-license.org/). See the LICENSE file for details.
## 🐞 Contributing
Contributions are welcome! Please submit a pull request or file an issue for any bugs or feature requests
on [GitHub](https://github.com/marianz-bonfire/tarsier_http_parser).

#### Why "Tarsier"?
The tarsier, one of the smallest primates, symbolizes simplicity and adaptability—just like this package! 🐒
