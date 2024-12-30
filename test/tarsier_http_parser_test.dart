import 'package:tarsier_http_parser/tarsier_http_parser.dart';
import 'package:test/test.dart';

import '../example/tarsier_http_parser_example.dart';

void main() {
  group('A group of tests', () {
    // Initialize the custom HTTP client with the User parser.
    final client = TarsierHttpClient<User>(
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      //expect(awesome.isAwesome, isTrue);
    });
  });
}
