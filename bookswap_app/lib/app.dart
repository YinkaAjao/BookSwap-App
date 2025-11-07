import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/core/providers/providers.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/main_navigation.dart';

class BookSwapApp extends ConsumerStatefulWidget {
  const BookSwapApp({super.key});

  @override
  ConsumerState<BookSwapApp> createState() => _BookSwapAppState();
}

class _BookSwapAppState extends ConsumerState<BookSwapApp> {
  bool _isThemeInitialized = false;
  bool _initializationError = false;

  @override
  void initState() {
    super.initState();
    // Initialize theme from Hive storage
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    try {
      await ref.read(themeProvider.notifier).initializeTheme();
      setState(() {
        _isThemeInitialized = true;
      });
    } catch (e) {
      print('Theme initialization error: $e');
      setState(() {
        _isThemeInitialized = true;
        _initializationError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    // Show loading until theme is initialized
    if (!_isThemeInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading BookSwap...',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show error state if initialization failed
    if (_initializationError) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load theme settings',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Using default theme',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeTheme,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'BookSwap',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: ref.watch(authStateProvider).when(
        data: (user) {
          if (user != null) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
        loading: () => Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Authentication Error'),
                Text(error.toString()),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}