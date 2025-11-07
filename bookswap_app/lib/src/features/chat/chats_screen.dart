import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/chat_model.dart';
import 'chat_screen.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  // Add WidgetRef parameter
    final userChatsAsync = ref.watch(userChatsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: userChatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading chats'),
              Text(error.toString()),
              ElevatedButton(
                onPressed: () => ref.invalidate(userChatsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text('Start a swap to begin chatting!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserName = chat.getOtherParticipantName(currentUser?.uid ?? '');
              
              return ChatListItem(
                chat: chat,
                otherUserName: otherUserName,
                onTap: () {
                  // FIXED: Use the correct method to set the selected chat
                  ref.read(selectedChatProvider.notifier).setChat(chat);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: chat),
                    ),
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

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final String otherUserName;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUserName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(otherUserName),
      subtitle: Text(
        chat.lastMessage.isNotEmpty 
            ? chat.lastMessage 
            : 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chat.lastMessageAt != null
          ? Text(
              _formatTime(chat.lastMessageAt!),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}