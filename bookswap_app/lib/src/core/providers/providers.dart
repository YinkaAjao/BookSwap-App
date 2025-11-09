import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  return ref.watch(authServiceProvider).verifiedAuthStateChanges;
});

// provider for unverified auth state (for verification screen)
final unverifiedAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// provider for verification status
final emailVerificationProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return Stream.value(user?.emailVerified ?? false);
});

// For verified users only (main app functionality)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// For unverified users (verification screen)
final currentUnverifiedUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(unverifiedAuthStateProvider);
  return authState.value;
});

// User ID providers for both verified and unverified users
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

final currentUnverifiedUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUnverifiedUserProvider);
  return user?.uid;
});

// Display name provider that works for any user state
final userDisplayNameProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.displayName;
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

// Notification Settings Provider
final notificationSettingsProvider = NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
  return NotificationSettingsNotifier();
});

class NotificationSettings {
  final bool swapNotifications;
  final bool chatNotifications;

  NotificationSettings({
    required this.swapNotifications,
    required this.chatNotifications,
  });

  NotificationSettings copyWith({
    bool? swapNotifications,
    bool? chatNotifications,
  }) {
    return NotificationSettings(
      swapNotifications: swapNotifications ?? this.swapNotifications,
      chatNotifications: chatNotifications ?? this.chatNotifications,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    // Default values for notification settings
    return NotificationSettings(
      swapNotifications: true,
      chatNotifications: true,
    );
  }

  void toggleSwapNotifications() {
    state = state.copyWith(swapNotifications: !state.swapNotifications);
  }

  void toggleChatNotifications() {
    state = state.copyWith(chatNotifications: !state.chatNotifications);
  }

  void setSwapNotifications(bool value) {
    state = state.copyWith(swapNotifications: value);
  }

  void setChatNotifications(bool value) {
    state = state.copyWith(chatNotifications: value);
  }
}

// Theme Provider
enum AppThemeMode { light, dark }

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const String _themeBoxName = 'themeBox';
  static const String _themeKey = 'isDarkMode';

  @override
  AppThemeMode build() {
    return AppThemeMode.light; // Default theme
  }

  // Initialize theme from Hive storage
  Future<void> initializeTheme() async {
    try {
      // Initialize Hive if not already initialized
      if (!Hive.isBoxOpen(_themeBoxName)) {
        await Hive.initFlutter();
      }
      
      // Open the theme box
      final box = await Hive.openBox(_themeBoxName);
      
      // Get the stored theme preference
      final isDarkMode = box.get(_themeKey, defaultValue: false) as bool;
      state = isDarkMode ? AppThemeMode.dark : AppThemeMode.light;
    } catch (e) {
      // If Hive fails, fall back to default light theme
      debugPrint('Error initializing theme: $e');
      state = AppThemeMode.light;
    }
  }

  // Toggle theme mode
  Future<void> toggleTheme() async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      final newThemeMode = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
      
      state = newThemeMode;
      await box.put(_themeKey, newThemeMode == AppThemeMode.dark);
    } catch (e) {
      debugPrint('Error toggling theme: $e');
      // Still update the state even if storage fails
      state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    }
  }

  // Set specific theme mode
  Future<void> setTheme(AppThemeMode mode) async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      state = mode;
      await box.put(_themeKey, mode == AppThemeMode.dark);
    } catch (e) {
      debugPrint('Error setting theme: $e');
      state = mode;
    }
  }

  // Check if dark mode is enabled
  bool get isDarkMode => state == AppThemeMode.dark;
}