
class Flyer {
  final String name;
  final String path; // Changed from Uint8List to String

  Flyer({required this.name, required this.path});

  // Convert a Flyer into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
      };

  // Implement a constructor that creates a Flyer from a map.
  factory Flyer.fromJson(Map<String, dynamic> json) => Flyer(
        name: json['name'],
        path: json['path'],
      );
}
