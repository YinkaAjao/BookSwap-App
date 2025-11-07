import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/swap_model.dart';
import '../models/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get booksCollection => _firestore.collection('books');
  CollectionReference get swapsCollection => _firestore.collection('swaps');
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get messagesCollection =>
      _firestore.collection('messages');

  // Create a new book listing
  Future<void> createBook(Book book) async {
    try {
      print('Creating book: ${book.title} for user: ${book.ownerId}');

      // Validate book data
      if (book.id.isEmpty) {
        throw Exception('Book ID cannot be empty');
      }
      if (book.title.isEmpty) {
        throw Exception('Book title cannot be empty');
      }
      if (book.ownerId.isEmpty) {
        throw Exception('Owner ID cannot be empty');
      }

      await booksCollection.doc(book.id).set(book.toJson());
      print('Book created successfully: ${book.id}');
    } catch (e) {
      print('Failed to create book: $e');
      print('Book data: ${book.toJson()}');
      throw Exception('Failed to create book: $e');
    }
  }

  // Get all books (for browse screen)
  Stream<List<Book>> getBooksStream() {
    return booksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Book.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get user's books
  Stream<List<Book>> getUserBooksStream(String userId) {
    return booksCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Book.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Update a book
  Future<void> updateBook(Book book) async {
    try {
      await booksCollection.doc(book.id).update(book.toJson());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      await booksCollection.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Get a single book by ID
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await booksCollection.doc(bookId).get();
      if (doc.exists) {
        return Book.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
  }

  // Create a swap request
  Future<void> createSwap(Swap swap) async {
    try {
      await swapsCollection.doc(swap.id).set(swap.toJson());

      // Update book availability
      await booksCollection.doc(swap.bookId).update({'isAvailable': false});
    } catch (e) {
      throw Exception('Failed to create swap: $e');
    }
  }

  // Get swaps where user is the owner
  Stream<List<Swap>> getOwnerSwapsStream(String userId) {
    return swapsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Swap.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get swaps where user is the requester
  Stream<List<Swap>> getRequesterSwapsStream(String userId) {
    return swapsCollection
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Swap.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Update swap status
  Future<void> updateSwapStatus(String swapId, SwapStatus status) async {
    try {
      await swapsCollection.doc(swapId).update({
        'status': status.index,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // If rejected, make book available again
      if (status == SwapStatus.rejected) {
        final swapDoc = await swapsCollection.doc(swapId).get();
        if (swapDoc.exists) {
          final swap = Swap.fromJson(swapDoc.data() as Map<String, dynamic>);
          await booksCollection.doc(swap.bookId).update({'isAvailable': true});
        }
      }
    } catch (e) {
      throw Exception('Failed to update swap: $e');
    }
  }

  // Get a single swap by ID
  Future<Swap?> getSwap(String swapId) async {
    try {
      final doc = await swapsCollection.doc(swapId).get();
      if (doc.exists) {
        return Swap.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get swap: $e');
    }
  }

  // Chat methods
  Future<Chat> getOrCreateChat(
    String swapId,
    List<String> participantIds,
    List<String> participantNames,
  ) async {
    try {
      // Check if chat already exists for this swap
      final existingChats = await chatsCollection
          .where('swapId', isEqualTo: swapId)
          .limit(1)
          .get();

      if (existingChats.docs.isNotEmpty) {
        return Chat.fromJson(
          existingChats.docs.first.data() as Map<String, dynamic>,
        );
      }

      // Create new chat
      final chat = Chat(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        swapId: swapId,
        participantIds: participantIds,
        participantNames: participantNames,
        createdAt: DateTime.now(),
      );

      await chatsCollection.doc(chat.id).set(chat.toJson());
      return chat;
    } catch (e) {
      throw Exception('Failed to get or create chat: $e');
    }
  }

  Stream<List<Chat>> getUserChatsStream(String userId) {
    return chatsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chat.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<Message>> getChatMessagesStream(String chatId) {
    return messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Message.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> sendMessage(Message message) async {
    try {
      // Add message to messages collection
      await messagesCollection.doc(message.id).set(message.toJson());

      // Update chat's last message and timestamp
      await chatsCollection.doc(message.chatId).update({
        'lastMessage': message.text,
        'lastMessageAt': message.timestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }
}
