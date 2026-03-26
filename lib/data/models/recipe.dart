class Recipe {
  final String id;
  final String name;
  final String image;
  final String category;
  final int week;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.category,
    required this.week,
  });

  factory Recipe.fromFirestore(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      category: data['category'] ?? '',
      week: data['week'] ?? 0,
    );
  }
}