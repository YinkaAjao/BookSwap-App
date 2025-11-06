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
  return FirestoreService.getBooksStream();
});

final userBooksStreamProvider = StreamProvider<List<Book>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return FirestoreService.getUserBooksStream(user.uid);
});

// Swap data providers 
final ownerSwapsStreamProvider = StreamProvider<List<Swap>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return FirestoreService.getOwnerSwapsStream(user.uid);
});

final requesterSwapsStreamProvider = StreamProvider<List<Swap>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return FirestoreService.getRequesterSwapsStream(user.uid);
});

// Selected swap provider
final selectedSwapProvider = Provider<Swap?>((ref) => null);

// Chat data providers
final userChatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return FirestoreService.getUserChatsStream(user.uid);
});

final chatMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return FirestoreService.getChatMessagesStream(chatId);
});

// Selected chat provider
final selectedChatProvider = StateProvider<Chat?>((ref) => null);

// Chat notifier for sending messages
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatState {
  final bool isLoading;
  final String? error;

  ChatState({
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}