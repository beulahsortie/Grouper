import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthScreen extends StatelessWidget {
  final void Function()? onLogin;
  const AuthScreen({Key? key, this.onLogin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Grouper', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Create an account\nEnter your email to sign up for this app', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: 'email@domain.com', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;
                  final user = await ApiService.login(email);
                  if (user != null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
                    if (onLogin != null) onLogin!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email')));
                  }
                },
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.g_mobiledata), label: const Text('Continue with Google')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.apple), label: const Text('Continue with Apple')),
          ],
        ),
      ),
    );
  }
}
