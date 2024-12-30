
[![pub package](https://img.shields.io/pub/v/tarsier_http_parser.svg)](https://pub.dev/packages/tarsier_http_parser)
[![package publisher](https://img.shields.io/pub/publisher/tarsier_http_parser.svg)](https://pub.dev/packages/tarsier_http_parser/publisher)


<img height="280" src="https://raw.githubusercontent.com/marianz-bonfire/tarsier_http_parser/master/assets/logo.png">

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
  tarsier_http_parser: ^1.0.0
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
Create an instance of TarsierHttpClient with the fromJson function:
```Dart
final client = TarsierHttpClient<User>(
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
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