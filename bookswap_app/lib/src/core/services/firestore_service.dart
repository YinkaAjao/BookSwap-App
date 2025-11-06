import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/swap_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get booksCollection => _firestore.collection('books');

  // Create a new book listing
  static Future<void> createBook(Book book) async {
    try {
      await booksCollection.doc(book.id).set(book.toJson());
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  // Get all books (for browse screen)
  static Stream<List<Book>> getBooksStream() {
    return booksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get user's books
  static Stream<List<Book>> getUserBooksStream(String userId) {
    return booksCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update a book
  static Future<void> updateBook(Book book) async {
    try {
      await booksCollection.doc(book.id).update(book.toJson());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Delete a book
  static Future<void> deleteBook(String bookId) async {
    try {
      await booksCollection.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Get a single book by ID
  static Future<Book?> getBook(String bookId) async {
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

  // Swap methods
static CollectionReference get swapsCollection => _firestore.collection('swaps');

// Create a swap request
static Future<void> createSwap(Swap swap) async {
  try {
    await swapsCollection.doc(swap.id).set(swap.toJson());
    
    // Update book availability
    await booksCollection.doc(swap.bookId).update({
      'isAvailable': false,
    });
  } catch (e) {
    throw Exception('Failed to create swap: $e');
  }
}

// Get swaps where user is the owner
static Stream<List<Swap>> getOwnerSwapsStream(String userId) {
  return swapsCollection
      .where('ownerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Swap.fromJson(doc.data() as Map<String, dynamic>))
          .toList());
}

// Get swaps where user is the requester
static Stream<List<Swap>> getRequesterSwapsStream(String userId) {
  return swapsCollection
      .where('requesterId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Swap.fromJson(doc.data() as Map<String, dynamic>))
          .toList());
}

// Update swap status
static Future<void> updateSwapStatus(String swapId, SwapStatus status) async {
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
        await booksCollection.doc(swap.bookId).update({
          'isAvailable': true,
        });
      }
    }
  } catch (e) {
    throw Exception('Failed to update swap: $e');
  }
}

// Get a single swap by ID
static Future<Swap?> getSwap(String swapId) async {
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
}

