import 'package:tarsier_http_parser/tarsier_http_parser.dart';

// Define a User class and its JSON factory method.
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

void main() async {
  // Initialize the custom HTTP client with the User parser.
  final client = TarsierHttpClient<User>(
    fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
  );

  try {
    // Perform a GET request.
    final result = await client.get(Uri.parse('https://api.example.com/user'));

    result
        .onSuccess((user) => print('User: ${user.name}'))
        .onError((error) => print('Error: $error'));

    // Perform a POST request.
    final postResult = await client.post(
      Uri.parse('https://api.example.com/user'),
      body: {'name': 'New User'},
    );

    postResult
        .onSuccess((user) => print('Created User: ${user.name}'))
        .onError((error) => print('Error: $error'));
  } finally {
    client.close(); // Ensure the client is closed after use.
  }
}
