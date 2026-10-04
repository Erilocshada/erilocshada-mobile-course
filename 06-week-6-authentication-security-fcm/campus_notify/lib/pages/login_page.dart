import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  ConsumerState<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    final email =
    _emailController.text.trim();

    final password =
    _passwordController.text.trim();

    final success =
    await ref.read(authProvider.notifier).login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      final error =
          ref.read(authProvider).errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Login gagal',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState =
    ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                'Campus Notification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Silakan login untuk melanjutkan',
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                keyboardType:
                TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.email,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.lock,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                  authState.isLoading
                      ? null
                      : _login,
                  child: authState.isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Demo Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Email: test@gmail.com\n'
                    'Password: 123456',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}