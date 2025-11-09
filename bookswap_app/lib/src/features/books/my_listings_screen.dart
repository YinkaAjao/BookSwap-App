import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/providers.dart';
import '../../core/models/book_model.dart';
import '../../core/models/swap_model.dart';
import '../chat/chat_screen.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBooksAsync = ref.watch(userBooksStreamProvider);
    final ownerSwapsAsync = ref.watch(ownerSwapsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBookScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: userBooksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          // Remove print statement and use debugPrint if needed
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading your books',
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
                  onPressed: () => ref.invalidate(userBooksStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No books listed yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to list your first book!'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddBookScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Book'),
                  ),
                ],
              ),
            );
          }

          return ownerSwapsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return MyBookCard(book: book);
              },
            ),
            data: (swaps) {
              // Group swaps by book ID
              final swapsByBookId = <String, List<Swap>>{};
              for (final swap in swaps) {
                if (!swapsByBookId.containsKey(swap.bookId)) {
                  swapsByBookId[swap.bookId] = [];
                }
                swapsByBookId[swap.bookId]!.add(swap);
              }

              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final bookSwaps = swapsByBookId[book.id] ?? [];
                  final pendingSwaps = bookSwaps.where((swap) => swap.isPending).toList();
                  
                  return MyBookCard(
                    book: book,
                    pendingSwaps: pendingSwaps,
                    allSwaps: bookSwaps,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class MyBookCard extends ConsumerStatefulWidget {
  final Book book;
  final List<Swap> pendingSwaps;
  final List<Swap> allSwaps;

  const MyBookCard({
    super.key,
    required this.book,
    this.pendingSwaps = const [],
    this.allSwaps = const [],
  });

  @override
  ConsumerState<MyBookCard> createState() => _MyBookCardState();
}

class _MyBookCardState extends ConsumerState<MyBookCard> {
  bool _isLoading = false;
  bool _showSwapRequests = false;

  Future<void> _updateSwapStatus(String swapId, SwapStatus status) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateSwapStatus(swapId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swap ${status.name}d successfully'),
            backgroundColor: status == SwapStatus.accepted ? Colors.green : Colors.red,
          ),
        );
      }
      
      // Refresh the swaps and books
      ref.invalidate(ownerSwapsStreamProvider);
      ref.invalidate(requesterSwapsStreamProvider);
      ref.invalidate(booksStreamProvider);
      ref.invalidate(userBooksStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update swap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat(Swap swap) async {
    final currentUser = ref.read(currentUserProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final participantIds = [swap.ownerId, swap.requesterId];
      final participantNames = [swap.ownerName, swap.requesterName];

      final chat = await firestoreService.getOrCreateChat(
        swap.id,
        participantIds,
        participantNames,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.green;
      case SwapStatus.rejected:
        return Colors.red;
      case SwapStatus.completed:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.read inside build method instead of making build method async
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: widget.book.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.book.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.book, size: 30, color: Colors.grey),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.book, size: 30, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.book, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${widget.book.author}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.book.isAvailable ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.book.isAvailable ? 'Available' : 'Pending Swap',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: widget.book.isAvailable ? Colors.green[800] : Colors.orange[800],
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.book.conditionText,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.blue[800],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      // Show pending swap count
                      if (widget.pendingSwaps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_active, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.pendingSwaps.length} pending swap${widget.pendingSwaps.length > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (widget.allSwaps.isNotEmpty)
                      PopupMenuItem(
                        value: 'toggle_swaps',
                        child: Row(
                          children: [
                            Icon(_showSwapRequests ? Icons.visibility_off : Icons.visibility, size: 20),
                            const SizedBox(width: 8),
                            Text(_showSwapRequests ? 'Hide Requests' : 'Show Requests'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBookScreen(book: widget.book),
                        ),
                      );
                    } else if (value == 'toggle_swaps') {
                      setState(() {
                        _showSwapRequests = !_showSwapRequests;
                      });
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Book'),
                          content: const Text('Are you sure you want to delete this book listing?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final firestoreService = ref.read(firestoreServiceProvider);
                          await firestoreService.deleteBook(widget.book.id);
                          
                          // Delete associated image if exists
                          if (widget.book.imageUrl.isNotEmpty) {
                            final storageService = ref.read(storageServiceProvider);
                            await storageService.deleteBookImage(widget.book.imageUrl);
                          }
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Book deleted successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete book: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            // Show swap requests if toggled
            if (_showSwapRequests && widget.allSwaps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Swap Requests (${widget.allSwaps.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...widget.allSwaps.map((swap) => _buildSwapRequestItem(swap)),
            ],
            // Show loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwapRequestItem(Swap swap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Requester info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested by: ${swap.requesterName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${_formatDate(swap.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(swap.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getStatusColor(swap.status)),
                ),
                child: Text(
                  swap.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(swap.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons based on status
          if (swap.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _updateSwapStatus(swap.id, SwapStatus.accepted),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _updateSwapStatus(swap.id, SwapStatus.rejected),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (swap.isAccepted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _startChat(swap),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('Chat with Requester'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}