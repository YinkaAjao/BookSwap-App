enum BookCondition { newCondition, likeNew, good, used }

class Book {
  final String id;
  final String title;
  final String author;
  final BookCondition condition;
  final String imageUrl;
  final String ownerId;
  final DateTime createdAt;
  final bool isAvailable;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.imageUrl,
    required this.ownerId,
    required this.createdAt,
    this.isAvailable = true,
  });

  // Add toJson/fromJson methods...
}