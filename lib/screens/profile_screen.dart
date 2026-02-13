import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getUserProfile(1), // Demo: userId=1
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading profile'));
          }
          final user = snapshot.data ?? {};
          final emailController = TextEditingController(text: user['email'] ?? '');
          final phoneController = TextEditingController(text: user['phone'] ?? '');
          final locationController = TextEditingController(text: user['location'] ?? '');
          return Column(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.orange.shade200, Colors.deepOrange.shade200]),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'email', hintText: 'abc123@gmail.com')),
                    const SizedBox(height: 8),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', hintText: '9999999999')),
                    const SizedBox(height: 8),
                    TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', hintText: 'Beulah, Texas')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ApiService.updateUserProfile(1, emailController.text, phoneController.text, locationController.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                        },
                        child: const Text('SAVE'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (onLogout != null) {
                            onLogout!();
                          } else {
                            // fallback: pop to root or show AuthScreen
                            Navigator.of(context).maybePop();
                          }
                        },
                        child: const Text('LOGOUT'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

