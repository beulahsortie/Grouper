import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/venue.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'groups_screen.dart';
import 'create_group_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int venueId;
  final Map<String, dynamic>? currentUser;
  const CheckoutScreen({required this.venueId, this.currentUser});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 9;
  int _durationHours = 1;
  Future<List<dynamic>>? _groupsFuture;
  bool _slotSelected = false;

  static const List<int> _durations = [1, 2, 3, 4];

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _startTimeStr =>
      '${_selectedHour.toString().padLeft(2, '0')}:00:00';
  String get _displayTime {
    final h = _selectedHour;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    return '$hour12:00 $suffix';
  }

  void _checkSlot() {
    setState(() {
      _slotSelected = true;
      _groupsFuture = ApiService.getGroups(
        venueId: widget.venueId,
        date: _dateStr,
        startTime: _startTimeStr,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _slotSelected = false;
      });
    }
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _PickerSheet(
        child: CupertinoPicker(
          scrollController:
              FixedExtentScrollController(initialItem: _selectedHour - 7),
          itemExtent: 44,
          magnification: 1.1,
          useMagnifier: true,
          onSelectedItemChanged: (i) => setState(() {
            _selectedHour = 7 + i;
            _slotSelected = false;
          }),
          children: List.generate(14, (i) {
            final h = 7 + i;
            final h12 = h > 12 ? h - 12 : h;
            final s = h >= 12 ? 'PM' : 'AM';
            return Center(
              child: Text('$h12:00 $s',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            );
          }),
        ),
      ),
    );
  }

  void _showDurationPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _PickerSheet(
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
              initialItem: _durations.indexOf(_durationHours)),
          itemExtent: 44,
          magnification: 1.1,
          useMagnifier: true,
          onSelectedItemChanged: (i) => setState(() {
            _durationHours = _durations[i];
            _slotSelected = false;
          }),
          children: _durations
              .map((d) => Center(
                    child: Text('$d ${d == 1 ? "hr" : "hrs"}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FutureBuilder<List<Venue>>(
        future: ApiService.getVenues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final venue = snapshot.data?.firstWhere(
                (v) => v.id == widget.venueId,
                orElse: () =>
                    Venue(id: 0, name: 'Unknown', price: 0, imageUrl: ''),
              ) ??
              Venue(id: 0, name: 'Unknown', price: 0, imageUrl: '');

          return CustomScrollView(
            slivers: [

              // ── Hero image ────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      Image.network(
                        venue.imageUrl,
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.navyLight,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.white38, size: 48),
                        ),
                      ),
                      // Dark gradient bottom fade
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.45, 1.0],
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                AppColors.cream,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      // Rating badge top right
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text('4.8',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      // Price badge bottom left on image
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$${venue.price.toStringAsFixed(0)} / hr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Venue name + address ─────────────────────
                      Text(venue.name,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.6)),
                      const SizedBox(height: 6),
                      if (venue.address != null)
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(venue.address!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ),
                        ]),

                      const SizedBox(height: 16),

                      // ── Info chips row ───────────────────────────
                      Row(
                        children: [
                          _InfoChip(
                              icon: Icons.people_rounded,
                              label: 'Up to 20'),
                          const SizedBox(width: 8),
                          _InfoChip(
                              icon: Icons.verified_rounded,
                              label: 'Verified'),
                          const SizedBox(width: 8),
                          _InfoChip(
                              icon: Icons.wifi_rounded,
                              label: 'WiFi'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── About ────────────────────────────────────
                      const Text('About this venue',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        'This venue is near the Metro Station and at around 200m walking distance. Perfect for sports activities, corporate events, and private gatherings. Fully equipped with changing rooms and on-site parking.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6),
                      ),

                      const SizedBox(height: 28),

                      // ── Divider ──────────────────────────────────
                      Container(
                          height: 1, color: AppColors.divider),

                      const SizedBox(height: 24),

                      // ── Book your slot heading ───────────────────
                      const Text('Book Your Slot',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),

                      // ── Date full row ────────────────────────────
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.divider, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.navy.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.navy.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.navy,
                                    size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                      DateFormat('EEE, dd MMM yyyy')
                                          .format(_selectedDate),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded,
                                  color: AppColors.textMuted, size: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Time + Duration in one row ───────────────
                      Row(
                        children: [
                          // Time
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTimePicker,
                              child: _SlotField(
                                icon: Icons.access_time_rounded,
                                label: 'Start Time',
                                value: _displayTime,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Duration
                          Expanded(
                            child: GestureDetector(
                              onTap: _showDurationPicker,
                              child: _SlotField(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value:
                                    '$_durationHours ${_durationHours == 1 ? "hr" : "hrs"}',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Price pill ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.navy.withOpacity(0.1),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                color: AppColors.navy, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '\$${venue.price.toStringAsFixed(0)} × $_durationHours ${_durationHours == 1 ? "hr" : "hrs"}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              '\$${(venue.price * _durationHours).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Check slot CTA ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _checkSlot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Check Availability  ·  $_displayTime',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Group availability result ─────────────────
                      if (_slotSelected && _groupsFuture != null) ...[
                        const SizedBox(height: 24),
                        const Text('Group Availability',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        FutureBuilder<List<dynamic>>(
                          future: _groupsFuture,
                          builder: (context, snap) {
                            if (snap.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snap.hasError) return const _ErrorCard();
                            final groups = snap.data ?? [];

                            if (groups.isNotEmpty) {
                              return _GroupsAvailableCard(
                                groups: groups,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GroupsScreen(
                                      venueId: widget.venueId,
                                      venueName: venue.name,
                                      date: _dateStr,
                                      startTime: _startTimeStr,
                                      displayTime: _displayTime,
                                      durationHours: _durationHours,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return _CreateGroupCard(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CreateGroupScreen(
                                      venueId: widget.venueId,
                                      venueName: venue.name,
                                      date: _dateStr,
                                      startTime: _startTimeStr,
                                      displayTime: _displayTime,
                                      durationHours: _durationHours,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared sheet wrapper for Cupertino pickers ────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final Widget child;
  const _PickerSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const Text('Done',
                  style: TextStyle(
                      color: AppColors.navy, fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Slot field widget ─────────────────────────────────────────────────────────

class _SlotField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SlotField(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.navy.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.navy, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.navy),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}

// ── Group cards ───────────────────────────────────────────────────────────────

class _GroupsAvailableCard extends StatelessWidget {
  final List<dynamic> groups;
  final VoidCallback onTap;
  const _GroupsAvailableCard({required this.groups, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navy, AppColors.navy.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.navy.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppColors.navy, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${groups.length} Group${groups.length > 1 ? 's' : ''} Available',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const Text('Tap to view and join a group',
                      style:
                          TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateGroupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.group_add_rounded,
                  color: AppColors.gold, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Groups Yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Be the first — create a group for this slot',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.navy, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.error.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          const Text('Could not check availability',
              style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ),
    );
  }
}