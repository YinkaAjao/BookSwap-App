import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

// Create a provider for notification settings
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authService = ref.read(authServiceProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view settings'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Display Name'),
                          subtitle: Text(user.displayName ?? 'Not set'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(user.email ?? 'No email'),
                        ),
                        ListTile(
                          leading: Icon(
                            user.emailVerified ? Icons.verified : Icons.warning,
                            color: user.emailVerified ? Colors.green : Colors.orange,
                          ),
                          title: const Text('Email Verification'),
                          subtitle: Text(
                            user.emailVerified ? 'Verified' : 'Not verified',
                          ),
                          trailing: !user.emailVerified
                              ? TextButton(
                                  onPressed: () {
                                    authService.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Verification email sent!'),
                                      ),
                                    );
                                  },
                                  child: const Text('Resend'),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notifications Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Swap Notifications'),
                          subtitle: const Text('Get notified when someone requests a swap'),
                          value: notificationSettings.swapNotifications,
                          onChanged: (value) {
                            ref.read(notificationSettingsProvider.notifier).setSwapNotifications(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value 
                                    ? 'Swap notifications enabled' 
                                    : 'Swap notifications disabled'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Chat Notifications'),
                          subtitle: const Text('Get notified for new messages'),
                          value: notificationSettings.chatNotifications,
                          onChanged: (value) {
                            ref.read(notificationSettingsProvider.notifier).setChatNotifications(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value 
                                    ? 'Chat notifications enabled' 
                                    : 'Chat notifications disabled'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _showSignOutDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }
}