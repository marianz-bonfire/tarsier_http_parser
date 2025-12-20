import 'package:tarsier_http_parser/tarsier_http_parser.dart';

class User {
  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.phone,
    required this.website,
    required this.company,
  });

  final int? id;
  final String? name;
  final String? username;
  final String? email;
  final Address? address;
  final String? phone;
  final String? website;
  final Company? company;

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    Address? address,
    String? phone,
    String? website,
    Company? company,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      company: company ?? this.company,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      username: json["username"],
      email: json["email"],
      address: json["address"] == null ? null : Address.fromJson(json["address"]),
      phone: json["phone"],
      website: json["website"],
      company: json["company"] == null ? null : Company.fromJson(json["company"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "username": username,
        "email": email,
        "address": address?.toJson(),
        "phone": phone,
        "website": website,
        "company": company?.toJson(),
      };
}

class Address {
  Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;
  final Geo? geo;

  Address copyWith({
    String? street,
    String? suite,
    String? city,
    String? zipcode,
    Geo? geo,
  }) {
    return Address(
      street: street ?? this.street,
      suite: suite ?? this.suite,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      geo: geo ?? this.geo,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json["street"],
      suite: json["suite"],
      city: json["city"],
      zipcode: json["zipcode"],
      geo: json["geo"] == null ? null : Geo.fromJson(json["geo"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "street": street,
        "suite": suite,
        "city": city,
        "zipcode": zipcode,
        "geo": geo?.toJson(),
      };
}

class Geo {
  Geo({
    required this.lat,
    required this.lng,
  });

  final String? lat;
  final String? lng;

  Geo copyWith({
    String? lat,
    String? lng,
  }) {
    return Geo(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(
      lat: json["lat"],
      lng: json["lng"],
    );
  }

  Map<String, dynamic> toJson() => {
        "lat": lat,
        "lng": lng,
      };
}

class Company {
  Company({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  final String? name;
  final String? catchPhrase;
  final String? bs;

  Company copyWith({
    String? name,
    String? catchPhrase,
    String? bs,
  }) {
    return Company(
      name: name ?? this.name,
      catchPhrase: catchPhrase ?? this.catchPhrase,
      bs: bs ?? this.bs,
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json["name"],
      catchPhrase: json["catchPhrase"],
      bs: json["bs"],
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "catchPhrase": catchPhrase,
        "bs": bs,
      };
}

// Define a Post class and its JSON factory method.
class Post {
  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int? userId;
  final int? id;
  final String? title;
  final String? body;

  Post copyWith({
    int? userId,
    int? id,
    String? title,
    String? body,
  }) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json["userId"],
      id: json["id"],
      title: json["title"],
      body: json["body"],
    );
  }

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "id": id,
        "title": title,
        "body": body,
      };
}

void main() async {
  // Initialize the custom HTTP client with the User parser.
  final client = TarsierHttpClient();

  // Get a User
  final userResult = await client.get<User>(
    Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
    fromJson: (json) => User.fromJson(json),
  );

  userResult.onSuccess((user) {
    print(user.name);
  });

  // Get a List of Posts
  final postsResult = await client.get<List<Post>>(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    fromJson: (json) => (json as List).map((e) => Post.fromJson(e)).toList(),
  );
  postsResult.onSuccess((posts) {
    for (var post in posts) {
      print(post.title);
    }
  });

  // Create a Role
  final postResult = await client.post<Post>(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    body: {'title': 'Admin'},
    fromJson: (json) => Post.fromJson(json),
  );

  postResult.onSuccess((post) {
    print(post.title);
  });
}
