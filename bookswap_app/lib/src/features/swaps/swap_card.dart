import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/swap_model.dart';
import '../../core/models/chat_model.dart';
import '../../core/providers/providers.dart';
import '../chat/chat_screen.dart';

class SwapCard extends ConsumerStatefulWidget {
  final Swap swap;
  final bool isOwner;

  const SwapCard({
    super.key,
    required this.swap,
    required this.isOwner,
  });

  @override
  ConsumerState<SwapCard> createState() => _SwapCardState();
}

class _SwapCardState extends ConsumerState<SwapCard> {
  bool _isLoading = false;

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

  Future<void> _startChat() async {
    final currentUser = ref.read(currentUserProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine participant IDs and names
      final participantIds = [widget.swap.ownerId, widget.swap.requesterId];
      final participantNames = [widget.swap.ownerName, widget.swap.requesterName];

      // Get or create chat
      final chat = await firestoreService.getOrCreateChat(
        widget.swap.id, // This is the swapId parameter
        participantIds,
        participantNames,
      );

      // Navigate to chat screen
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

  @override
  Widget build(BuildContext context) {
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
                  child: widget.swap.bookImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.swap.bookImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.book),
                          ),
                        )
                      : const Icon(Icons.book, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Swap details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.swap.bookTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isOwner 
                          ? 'Requested by: ${widget.swap.requesterName}'
                          : 'Owner: ${widget.swap.ownerName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.swap.status).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getStatusColor(widget.swap.status)),
                        ),
                        child: Text(
                          widget.swap.statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(widget.swap.status),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Requested: ${_formatDate(widget.swap.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (widget.swap.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Updated: ${_formatDate(widget.swap.updatedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions for owner
                if (widget.isOwner && widget.swap.isPending && !_isLoading)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'accept',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Accept'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Reject'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'accept') {
                        await _updateSwapStatus(widget.swap.id, SwapStatus.accepted);
                      } else if (value == 'reject') {
                        await _updateSwapStatus(widget.swap.id, SwapStatus.rejected);
                      }
                    },
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            // Chat button - available for both parties when swap is pending or accepted
            if ((widget.swap.isPending || widget.swap.isAccepted) && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Start Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSwapStatus(String swapId, SwapStatus status) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // FIXED: Use instance method from provider
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
      
      // Refresh the swaps
      ref.invalidate(ownerSwapsStreamProvider);
      ref.invalidate(requesterSwapsStreamProvider);
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}