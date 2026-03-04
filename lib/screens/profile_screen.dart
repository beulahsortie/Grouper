import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import '../widgets/image_picker_widget.dart';
import 'location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;
  const ProfileScreen({Key? key, this.currentUser, this.onLogout}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    final userId = widget.currentUser?['id'] ?? 1;
    _profileFuture = ApiService.getUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          }
          final user = snapshot.data ?? {};
          return _ProfileBody(
            user: user,
            onLogout: widget.onLogout,
            currentUser: widget.currentUser,
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;
  const _ProfileBody({required this.user, this.currentUser, this.onLogout});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  String? _avatarUrl;
  LatLng? _pickedLatLng;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.user['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.user['phone'] ?? '');
    _locationController =
        TextEditingController(text: widget.user['location'] ?? '');
    _avatarUrl = widget.user['avatar_url'];
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userId = widget.currentUser?['id'] ?? widget.user['id'] ?? 1;
    await ApiService.updateUserProfile(
      userId,
      _emailController.text,
      _phoneController.text,
      _locationController.text,
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 32,
            ),
            child: Column(
              children: [
                // Avatar with S3 upload
                ImagePickerWidget(
                  size: 88,
                  circular: true,
                  initialUrl: _avatarUrl,
                  onUploaded: (url) {
                    setState(() => _avatarUrl = url);
                    final userId = widget.currentUser?['id'] ?? widget.user['id'] ?? 1;
                    ApiService.updateUserProfile(
                      userId,
                      _emailController.text,
                      _phoneController.text,
                      _locationController.text,
                      avatarUrl: url,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user['name'] ?? 'Your Name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Form ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Info',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _Field(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded),
                  const SizedBox(height: 12),
                  _Field(
                      label: 'Phone',
                      controller: _phoneController,
                      icon: Icons.phone_outlined),
                  const SizedBox(height: 12),

                  // ── Location via map ─────────────────────────
                  const Text('Location',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<LatLng>(
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(
                              initialLocation: _pickedLatLng),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _pickedLatLng = result;
                          _locationController.text =
                              '${result.latitude.toStringAsFixed(5)}, '
                              '${result.longitude.toStringAsFixed(5)}';
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _pickedLatLng != null
                            ? AppColors.navy.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _pickedLatLng != null
                              ? AppColors.navy
                              : AppColors.divider,
                          width: _pickedLatLng != null ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedLatLng != null
                                ? Icons.location_on_rounded
                                : Icons.add_location_alt_rounded,
                            size: 18,
                            color: _pickedLatLng != null
                                ? AppColors.navy
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _pickedLatLng != null
                                  ? '${_pickedLatLng!.latitude.toStringAsFixed(5)}, '
                                    '${_pickedLatLng!.longitude.toStringAsFixed(5)}'
                                  : 'Tap to select on map',
                              style: TextStyle(
                                fontSize: 14,
                                color: _pickedLatLng != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Logout ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Log out',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _Field(
      {required this.label,
      required this.controller,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}