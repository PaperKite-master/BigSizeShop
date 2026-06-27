import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkEspresso = Color(0xFF3D251E);
    const primaryGold = Color(0xFFB58920);
    const goldAccent = Color(0xFFC59B27);
    const softCream = Color(0xFFFFFDF9);

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            letterSpacing: 3.0,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    decoration: BoxDecoration(
                      color: softCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4C5A3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0F3D251E), // darkEspresso with 0.06 opacity
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE4D7BA), width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_person_outlined,
                              size: 64,
                              color: goldAccent,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'ACCESS RESTRICTED',
                              style: TextStyle(
                                color: darkEspresso,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please sign in to access your classic membership wardrobe and details.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xB23D251E), // darkEspresso with 0.7 opacity
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('SIGN IN NOW'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Dotted Leader helper widget
          Widget buildLedgerRow(String label, String value) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: primaryGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dotCount = (constraints.maxWidth / 6).floor();
                        return Text(
                          '.' * (dotCount > 0 ? dotCount : 2),
                          style: const TextStyle(
                            color: Color(0xFFE4D7BA),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w600,
                      color: darkEspresso,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  // Classical Membership Passport Card
                  decoration: BoxDecoration(
                    color: softCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4C5A3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x143D251E), // darkEspresso with 0.08 opacity
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE4D7BA), width: 1.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vintage Avatar Frame
                          Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: goldAccent, width: 2.0),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: darkEspresso, width: 1.0),
                                  color: const Color(0xFFEFE6D4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: darkEspresso,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Member Title
                          Text(
                            user.fullName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: darkEspresso,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BIGSIZE SHOP MEMBER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0x993D251E), // darkEspresso with 0.6 opacity
                              letterSpacing: 2.0,
                            ),
                          ),
                          
                          // Classic separator
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('♦', style: TextStyle(color: goldAccent, fontSize: 14)),
                                ),
                                Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                              ],
                            ),
                          ),

                          // Ledger Rows
                          buildLedgerRow('EMAIL ADDRESS', user.email),
                          buildLedgerRow(
                            'MEMBER ROLE',
                            user.role.toUpperCase(),
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            buildLedgerRow('PHONE NUMBER', user.phone!),
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          if (user.isAdmin) ...[
                            FilledButton.icon(
                              onPressed: () => context.go('/admin'),
                              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                              label: const Text('ADMIN PANEL'),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryGold,
                                side: const BorderSide(color: goldAccent, width: 1),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(authControllerProvider.notifier).logout();
                              if (context.mounted) {
                                AppSnackBar.showSuccess(context, 'Logged out');
                                context.go('/');
                              }
                            },
                            child: const Text('LOGOUT'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
