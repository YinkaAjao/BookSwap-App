// models/chat_model.dart

class Chat {
  final String id;
  final String swapId;
  final List<String> participantIds;
  final List<String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.swapId,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage = '',
    this.lastMessageAt,
    required this.createdAt,
  });

  String getOtherParticipantName(String currentUserId) {
    final index = participantIds.indexOf(currentUserId);
    return participantNames[index == 0 ? 1 : 0];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'swapId': swapId,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Chat fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      swapId: json['swapId'],
      participantIds: List<String>.from(json['participantIds']),
      participantNames: List<String>.from(json['participantNames']),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      text: json['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}