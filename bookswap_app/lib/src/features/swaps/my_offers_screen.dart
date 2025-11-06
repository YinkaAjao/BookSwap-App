import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/providers.dart';
import '../../core/models/swap_model.dart';
import 'swap_card.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requesterSwapsAsync = ref.watch(requesterSwapsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
      ),
      body: requesterSwapsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading your offers'),
              Text(error.toString()),
              ElevatedButton(
                onPressed: () => ref.invalidate(requesterSwapsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
                  const Text('Browse books and make your first swap offer!'),
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