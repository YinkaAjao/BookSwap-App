enum SwapStatus { pending, accepted, rejected, completed }

class Swap {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookImageUrl;
  final String ownerId;
  final String ownerName;
  final String requesterId;
  final String requesterName;
  final SwapStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Swap({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookImageUrl': bookImageUrl,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'status': status.index,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  factory Swap.fromJson(Map<String, dynamic> json) => Swap(
        id: json['id'],
        bookId: json['bookId'],
        bookTitle: json['bookTitle'],
        bookImageUrl: json['bookImageUrl'],
        ownerId: json['ownerId'],
        ownerName: json['ownerName'],
        requesterId: json['requesterId'],
        requesterName: json['requesterName'],
        status: SwapStatus.values[json['status']],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
            : null,
      );

  Swap copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookImageUrl,
    String? ownerId,
    String? ownerName,
    String? requesterId,
    String? requesterName,
    SwapStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Swap(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookImageUrl: bookImageUrl ?? this.bookImageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusText {
    switch (status) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
      case SwapStatus.completed:
        return 'Completed';
    }
  }

  bool get isPending => status == SwapStatus.pending;
  bool get isAccepted => status == SwapStatus.accepted;
  bool get isRejected => status == SwapStatus.rejected;
}