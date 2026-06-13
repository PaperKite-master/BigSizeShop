import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You are not logged in'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(user.email),
              const SizedBox(height: 8),
              Chip(label: Text(user.role)),
              if (user.phone != null) ...[
                const SizedBox(height: 8),
                Text('Phone: ${user.phone}'),
              ],
              const SizedBox(height: 24),
              if (user.isAdmin)
                FilledButton.icon(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin panel'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    AppSnackBar.showSuccess(context, 'Logged out');
                    context.go('/');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
