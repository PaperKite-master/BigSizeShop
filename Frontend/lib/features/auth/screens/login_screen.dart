import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        final error = authState.error;
        AppSnackBar.showError(
          context,
          error is ApiException ? error.message : 'Login failed',
        );
        return;
      }

      AppSnackBar.showSuccess(context, 'Welcome back!');
      context.go('/');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkEspresso = Color(0xFF3D251E);
    const goldAccent = Color(0xFFC59B27);
    const parchmentCream = Color(0xFFFAF6EE);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BIGSIZE SHOP',
          style: TextStyle(
            letterSpacing: 3.0,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              // Outer vintage card decoration
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                padding: const EdgeInsets.all(4), // spacing for the double border
                child: Container(
                  // Inner delicate border
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE4D7BA), width: 1.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Monogram Logo Area
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: goldAccent, width: 2.0),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: darkEspresso, width: 1.0),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'BS',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: darkEspresso,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'WELCOME BACK',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: darkEspresso,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your classical wardrobe',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0x993D251E), // darkEspresso with 0.6 opacity
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        
                        // Vintage Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '♦',
                                  style: TextStyle(
                                    color: goldAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                            ],
                          ),
                        ),

                        // Form Fields
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: darkEspresso),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, color: darkEspresso, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: darkEspresso),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined, color: darkEspresso, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0x993D251E), // darkEspresso with 0.6 opacity
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(parchmentCream),
                                  ),
                                )
                              : const Text('SIGN IN'),
                        ),
                        
                        // Vintage Footer Divider
                        const Padding(
                          padding: EdgeInsets.only(top: 28, bottom: 12),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.hourglass_empty, size: 10, color: goldAccent),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE4D7BA))),
                            ],
                          ),
                        ),
                        
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'CREATE NEW ACCOUNT',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
