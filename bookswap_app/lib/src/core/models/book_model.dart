enum BookCondition { newCondition, likeNew, good, used }

class Book {
  final String id;
  final String title;
  final String author;
  final BookCondition condition;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final bool isAvailable;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'condition': condition.index,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isAvailable': isAvailable,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        condition: BookCondition.values[json['condition']],
        imageUrl: json['imageUrl'],
        ownerId: json['ownerId'],
        ownerName: json['ownerName'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        isAvailable: json['isAvailable'] ?? true,
      );

  Book copyWith({
    String? id,
    String? title,
    String? author,
    BookCondition? condition,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  String get conditionText {
    switch (condition) {
      case BookCondition.newCondition:
        return 'New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.used:
        return 'Used';
    }
  }
}