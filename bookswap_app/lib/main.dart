import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue running the app even if Firebase fails
    print('Firebase initialization error: $e');
  }

  // Initialize Hive
  try {
    await Hive.initFlutter();
  } catch (e) {
    print('Hive initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: BookSwapApp(),
    ),
  );
}