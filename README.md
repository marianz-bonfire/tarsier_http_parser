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

## ✨ Features

- **Simple API**: Includes basic HTTP methods like `GET`, `POST`, and `DELETE`.
- **Dynamic Parsing**: Supports generic types for flexible JSON-to-object conversion.
- **Error Handling**: Encapsulates success and error states using the `Result<T>` class.
- **No Inheritance**: Avoids unnecessary inheritance from `http.Client` for a minimal and focused API.

## 🚀 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  tarsier_http_parser: ^1.0.1
```
Run the following command:
```bash
flutter pub get
```
## 📒 Usage
- ### Define a Data Model
Create a data model that includes a `fromJson` factory constructor:
```Dart
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
```Dart
final client = TarsierHttpClient<User>(
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```
For a list of objects:
```Dart
final client = TarsierHttpClient<List<User>>(
    fromJson: (json) => (json as List).map((item) => User.fromJson(item)).toList(),
);
```

- ### Make HTTP Requests
GET Request
```Dart
final result = await client.get(Uri.parse('https://api.example.com/user'));

result
  .onSuccess((user) => print('User: ${user.name}'))
  .onError((error) => print('Error: $error'));
```
POST Request
```Dart
final postResult = await client.post(
  Uri.parse('https://api.example.com/user'),
  body: {'name': 'New User'},
);

postResult
  .onSuccess((user) => print('Created User: ${user.name}'))
  .onError((error) => print('Error: $error'));
```
DELETE Request
```dart
final deleteResult = await client.delete(Uri.parse('https://api.example.com/user/123'));

deleteResult
  .onSuccess((data) => print('User deleted'))
  .onError((error) => print('Error: $error'));
```
## 🎖️ License
This project is licensed under the [MIT License](https://mit-license.org/). See the LICENSE file for details.
## 🐞 Contributing
Contributions are welcome! Please submit a pull request or file an issue for any bugs or feature requests
on [GitHub](https://github.com/marianz-bonfire/tarsier_http_parser).

#### Why "Tarsier"?
The tarsier, one of the smallest primates, symbolizes simplicity and adaptability—just like this package! 🐒
