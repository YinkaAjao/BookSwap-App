import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';
import '../models/swap_model.dart';
import '../models/chat_model.dart';

// Firebase Services
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final storageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

// App Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(storageProvider));
});
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Auth State Providers
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// User ID Provider (for swap providers)
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// Book Data Providers
final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBooksStream();
});

final userBooksStreamProvider = StreamProvider<List<Book>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return firestoreService.getUserBooksStream(user.uid);
});

// Swap data providers 
final ownerSwapsStreamProvider = StreamProvider<List<Swap>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return firestoreService.getOwnerSwapsStream(user.uid);
});

final requesterSwapsStreamProvider = StreamProvider<List<Swap>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return firestoreService.getRequesterSwapsStream(user.uid);
});

// Selected swap provider
final selectedSwapProvider = Provider<Swap?>((ref) => null);

// Chat data providers
final userChatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return firestoreService.getUserChatsStream(user.uid);
});

final chatMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getChatMessagesStream(chatId);
});

// Simple state providers using NotifierProvider for Riverpod 3.0
final selectedChatProvider = NotifierProvider<SelectedChatNotifier, Chat?>(SelectedChatNotifier.new);

class SelectedChatNotifier extends Notifier<Chat?> {
  @override
  Chat? build() {
    return null;
  }

  void setChat(Chat? chat) {
    state = chat;
  }
}

final chatLoadingProvider = NotifierProvider<ChatLoadingNotifier, bool>(ChatLoadingNotifier.new);

class ChatLoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool loading) {
    state = loading;
  }
}

final chatErrorProvider = NotifierProvider<ChatErrorNotifier, String?>(ChatErrorNotifier.new);

class ChatErrorNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setError(String? error) {
    state = error;
  }
}