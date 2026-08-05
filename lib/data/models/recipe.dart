import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String category;
  final String thumbnail;
  final String ingredientTitle;
  final List<String> ingredients;
  final List<RecipeStep> steps;
  final String authorId;
  final String authorName;
  final String authorLocation;
  final String authorAvatar;
  final String userId;
  final String status;
  final String reviewReason;
  final String createdByRole;
  final String? draftId;
  final bool isAdmin;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnail,
    required this.ingredientTitle,
    required this.ingredients,
    required this.steps,
    this.authorId = "admin",
    this.authorName = "Admin",
    this.authorLocation = "Hà Nội - Việt Nam",
    this.authorAvatar = "",
    this.userId = "",
    this.status = "published",
    this.reviewReason = "",
    this.createdByRole = "admin",
    this.draftId,
    this.isAdmin = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      thumbnail: json['thumbnail'] ?? json['image'] ?? json['imageUrl'] ?? '',
      ingredientTitle: json['ingredientTitle'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => RecipeStep.fromJson(Map<String, dynamic>.from(step)),)
              .toList() ??
          [],
      authorId: json['authorId'] ?? "admin",
      authorName: json['authorName'] ?? "Admin",
      authorLocation: json['authorLocation'] ?? "Hà Nội - Việt Nam",
      authorAvatar: json['authorAvatar'] ?? "",
      isAdmin: json['isAdmin'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      thumbnail: data['thumbnail'] ?? data['image'] ?? data['imageUrl'] ?? '',
      ingredientTitle: data['ingredientTitle'] ?? 'Nguyên liệu',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: (data['steps'] as List<dynamic>?)
              ?.map((step) =>RecipeStep.fromJson(Map<String, dynamic>.from(step)),)
              .toList() ??
          [],
      authorId: data['authorId'] ?? data['userId'] ?? 'admin',
      authorName: data['authorName'] ?? data['userName'] ?? 'Admin',
      authorLocation: data['authorLocation'] ?? 'Việt Nam',
      authorAvatar: data['authorAvatar'] ?? data['userAvatar'] ?? "",
      userId: data['userId'] ?? data['authorId'] ?? '',
      status: data['status'] ?? 'published',
      reviewReason: data['reviewReason'] ?? '',
      createdByRole: data['createdByRole'] ?? (data['isAdmin'] == true ? 'admin' : 'user'),
      draftId: data['draftId'],
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "category": category,
      "thumbnail": thumbnail,
      "ingredientTitle": ingredientTitle,
      "ingredients": ingredients,
      "steps": steps.map((e) => e.toJson()).toList(),
      "authorId": authorId,
      "authorName": authorName,
      "authorLocation": authorLocation,
      "authorAvatar": authorAvatar,
      "isAdmin": isAdmin,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "name": name,
      "title": name,
      "category": category,
      "thumbnail": thumbnail,
      "image": thumbnail,
      "imageUrl": thumbnail,
      "ingredientTitle": ingredientTitle,
      "ingredients": ingredients,
      "steps": steps.map((e) => e.toJson()).toList(),
      "authorId": authorId,
      "authorName": authorName,
      "authorLocation": authorLocation,
      "authorAvatar": authorAvatar,
      "userId": userId,
      "userName": authorName,
      "userAvatar": authorAvatar,
      "status": status,
      "reviewReason": reviewReason,
      "createdByRole": createdByRole,
      if (draftId != null) "draftId": draftId,
      "isAdmin": isAdmin,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}

class RecipeStep {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> images;
  RecipeStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.images = const [],
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['stepNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "stepNumber": stepNumber,
      "title": title,
      "description": description,
      "images": images,
    };
  }
}