import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';

class CreateGroupScreen extends StatefulWidget {
  final int venueId;
  final String venueName;
  final String date;
  final String startTime;
  final String displayTime;
  final int durationHours;
  final Map<String, dynamic>? currentUser;

  const CreateGroupScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.displayTime,
    required this.durationHours,
    this.currentUser,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _maxMembers = 10;
  bool _submitting = false;

  static const List<int> _memberOptions = [4, 6, 8, 10, 12, 16, 20];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = widget.currentUser?['id'] as int?;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a group')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.createGroup(
        venueId: widget.venueId,
        date: widget.date,
        startTime: widget.startTime,
        durationHours: widget.durationHours,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        maxMembers: _maxMembers,
        createdBy: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Group created! You\'ve been added as the first member.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
          // ── Header ────────────────────────────────────────────
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create a Group',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        Text('Invite others to join your session',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Slot summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stadium_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.venueName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                      Text(
                        '${widget.displayTime}  ·  ${widget.date}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group name
                    _label('Group Name'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Group name is required'
                          : null,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      decoration: _inputDeco(
                        hint: 'e.g. Sunday Warriors',
                        icon: Icons.group_rounded,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Description
                    _label('Description (optional)'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: _inputDeco(
                        hint: 'e.g. Casual 5-a-side, all skill levels welcome',
                        icon: Icons.notes_rounded,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Max members
                    _label('Maximum Members'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _memberOptions.map((n) {
                        final isSelected = _maxMembers == n;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _maxMembers = n),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 180),
                            width: 68,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navy
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.navy
                                    : AppColors.divider,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text('$n',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors
                                                .textPrimary)),
                                Text('players',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: isSelected
                                            ? Colors.white60
                                            : AppColors
                                                .textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // Session summary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.navy.withOpacity(0.12),
                            width: 1.5),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(Icons.stadium_rounded,
                              'Venue', widget.venueName),
                          const SizedBox(height: 10),
                          _SummaryRow(Icons.calendar_today_rounded,
                              'Date', widget.date),
                          const SizedBox(height: 10),
                          _SummaryRow(Icons.schedule_rounded,
                              'Time', widget.displayTime),
                          const SizedBox(height: 10),
                          _SummaryRow(
                              Icons.timer_rounded,
                              'Duration',
                              '${widget.durationHours} ${widget.durationHours == 1 ? 'hour' : 'hours'}'),
                          const SizedBox(height: 10),
                          _SummaryRow(Icons.people_rounded,
                              'Max Members', '$_maxMembers players'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.navy.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5))
                            : const Text('Create Group',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));

  InputDecoration _inputDeco(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      hintStyle:
          const TextStyle(fontSize: 13, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.navy, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.navy),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}