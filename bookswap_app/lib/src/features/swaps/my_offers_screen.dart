import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'swap_card.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final requesterSwapsAsync = ref.watch(requesterSwapsStreamProvider);

    // Check if user is logged in
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Offers')),
        body: const Center(
          child: Text('Please sign in to view your offers'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
      ),
      body: requesterSwapsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your offers...'),
            ],
          ),
        ),
        error: (error, stack) {
          debugPrint('Error loading requester swaps: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading your offers',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(requesterSwapsStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (swaps) {
          if (swaps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No swap offers yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse books and make your first swap offer!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: swaps.length,
            itemBuilder: (context, index) {
              final swap = swaps[index];
              return SwapCard(swap: swap, isOwner: false);
            },
          );
        },
      ),
    );
  }
}