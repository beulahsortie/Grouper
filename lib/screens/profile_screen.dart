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
  const ProfileScreen({Key? key, this.currentUser, this.onLogout})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// KEY FIX: everything is in ONE StatefulWidget.
// No FutureBuilder, no _ProfileBody child widget.
// Controllers are created once in initState and never recreated.
class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();

  Map<String, dynamic> _user = {};
  String? _avatarUrl;
  LatLng?  _pickedLatLng;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = widget.currentUser?['id'] ?? 1;
      final user   = await ApiService.getUserProfile(userId);
      if (!mounted) return;
      setState(() {
        _user                    = user;
        _emailController.text    = user['email']    ?? '';
        _phoneController.text    = user['phone']    ?? '';
        _locationController.text = user['location'] ?? '';
        _avatarUrl               = user['avatar_url'];
        _loading                 = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final userId = widget.currentUser?['id'] ?? _user['id'] ?? 1;
    await ApiService.updateUserProfile(
      userId,
      _emailController.text,
      _phoneController.text,
      _locationController.text,
      name:      _user['name'],   // always pass name so it never gets wiped
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BgScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BgScaffold(
      body: GestureDetector(
        // tap anywhere outside a field to dismiss keyboard
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 32,
                ),
                child: Column(
                  children: [
                    ImagePickerWidget(
                      size: 88,
                      circular: true,
                      initialUrl: _avatarUrl,
                      onUploaded: (url) {
                        setState(() => _avatarUrl = url);
                        // immediately persist avatar url to DB
                        final userId =
                            widget.currentUser?['id'] ?? _user['id'] ?? 1;
                        ApiService.updateUserProfile(
                          userId,
                          _emailController.text,
                          _phoneController.text,
                          _locationController.text,
                          name:      _user['name'],
                          avatarUrl: url,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user['name'] ?? 'Your Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Form ────────────────────────────────────────────
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
                        label:        'Email',
                        controller:   _emailController,
                        icon:         Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label:        'Phone',
                        controller:   _phoneController,
                        icon:         Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // ── Location via map ───────────────────────
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
                          onPressed: _saving ? null : _saveProfile,
                          child: _saving
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Logout ────────────────────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      controller,
      keyboardType:    keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}