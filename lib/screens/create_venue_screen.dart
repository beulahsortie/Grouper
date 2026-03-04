import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import '../widgets/image_picker_widget.dart';
import 'location_picker_screen.dart';

class CreateVenueScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  const CreateVenueScreen({super.key, this.currentUser});

  @override
  State<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends State<CreateVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  String? _uploadedImageUrl;
  LatLng? _pickedLatLng;
  String? _pickedAddress;

  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _loadingCategories = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        _loadingCategories = false;
      });
    } catch (_) {
      setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a venue photo'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.createVenue(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: _uploadedImageUrl!,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: _pickedLatLng?.latitude,
        longitude: _pickedLatLng?.longitude,
        categoryId: _selectedCategoryId,
        createdBy: widget.currentUser?['id'] as int?,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Venue created successfully!'),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true); // return true so HomeScreen can refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create venue: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a Venue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'List your space for sports activities',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Venue Photo'),
                    const SizedBox(height: 12),
                    Center(
                      child: ImagePickerWidget(
                        size: 160,
                        circular: false,
                        initialUrl: _uploadedImageUrl,
                        onUploaded: (url) =>
                            setState(() => _uploadedImageUrl = url),
                      ),
                    ),
                    if (_uploadedImageUrl != null) ...[
                      const SizedBox(height: 8),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 14),
                            SizedBox(width: 4),
                            Text('Photo uploaded',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.success)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Basic Info'),
                    const SizedBox(height: 12),

                    _Field(
                      controller: _nameController,
                      label: 'Venue Name',
                      hint: 'e.g. City Football Ground',
                      icon: Icons.stadium_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    _Field(
                      controller: _priceController,
                      label: 'Price per session (\$)',
                      hint: 'e.g. 50',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price is required';
                        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Category'),
                    const SizedBox(height: 12),

                    _loadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : _CategoryPicker(
                            categories: _categories,
                            selected: _selectedCategoryId,
                            onSelected: (id) =>
                                setState(() => _selectedCategoryId = id),
                          ),

                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Location (optional)'),
                    const SizedBox(height: 12),

                    _Field(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'e.g. Al Wasl Rd, Dubai',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),

                    // ── Map location picker ───────────────────────
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.of(context).push<LatLng>(
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              initialLocation: _pickedLatLng,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => _pickedLatLng = result);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _pickedLatLng != null
                                    ? AppColors.navy
                                    : AppColors.cardBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _pickedLatLng != null
                                    ? Icons.location_on_rounded
                                    : Icons.add_location_alt_rounded,
                                color: _pickedLatLng != null
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _pickedLatLng != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Location Selected',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_pickedLatLng!.latitude.toStringAsFixed(5)}, '
                                          '${_pickedLatLng!.longitude.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    )
                                  : const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Select on Map',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                        Text('Tap to open map and pin location',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary)),
                                      ],
                                    ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: _pickedLatLng != null
                                  ? AppColors.navy
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.navy.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Create Venue',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<dynamic> categories;
  final int? selected;
  final void Function(int id) onSelected;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories available',
          style: TextStyle(color: AppColors.textMuted));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = selected == cat.id;
        return GestureDetector(
          onTap: () => onSelected(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navy : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.navy : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    cat.imageUrl,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.category_rounded,
                        size: 18,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cat.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}