import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import 'group_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  const ActivitiesScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _groupsFuture;
  late Future<List<dynamic>> _venuesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _groupsFuture = widget.currentUser != null
        ? ApiService.getUserGroups(widget.currentUser!['id'])
        : Future.value([]);
    _venuesFuture = widget.currentUser != null
        ? ApiService.getUserVenues(widget.currentUser!['id'])
        : Future.value([]);
  }

  Future<void> _refresh() async {
    final groups = widget.currentUser != null
        ? ApiService.getUserGroups(widget.currentUser!['id'])
        : Future.value(<dynamic>[]);
    final venues = widget.currentUser != null
        ? ApiService.getUserVenues(widget.currentUser!['id'])
        : Future.value(<dynamic>[]);
    await Future.wait([groups, venues]);
    if (!mounted) return;
    setState(() {
      _groupsFuture = groups;
      _venuesFuture = venues;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              bottom: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activities',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.7)),
                const SizedBox(height: 2),
                Text('Your bookings & listed venues',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.55))),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.gold,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.45),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Booking History'),
                    Tab(text: 'My Venues'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _GroupsTab(
                  future: _groupsFuture,
                  isLoggedIn: widget.currentUser != null,
                  currentUser: widget.currentUser,
                  onRefresh: _refresh,
                ),
                _MyVenuesTab(
                  future: _venuesFuture,
                  isLoggedIn: widget.currentUser != null,
                  onRefresh: _refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Groups Tab ────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  final Future<List<dynamic>> future;
  final bool isLoggedIn;
  final Map<String, dynamic>? currentUser;
  final Future<void> Function() onRefresh;
  const _GroupsTab({
    required this.future,
    required this.isLoggedIn,
    required this.currentUser,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const _NotLoggedInState(message: 'Sign in to see your groups');
    }
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _ErrorState(message: 'Error loading groups');
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.navy,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: const [
                _EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'No groups yet',
                  subtitle: 'Groups you join or create will appear here',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.navy,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GroupActivityCard(
              group: groups[i],
              currentUser: currentUser,
            ),
          ),
        );
      },
    );
  }
}

class _GroupActivityCard extends StatelessWidget {
  final dynamic group;
  final Map<String, dynamic>? currentUser;
  const _GroupActivityCard({required this.group, this.currentUser});

  String _formatTime(String? t) {
    if (t == null) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    return '$h12:00 $suffix';
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    // d is "2025-01-15T00:00:00.000Z" or "2025-01-15"
    return d.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = group['member_count'] ?? 0;
    final maxMembers = group['max_members'] ?? 10;
    final isOwner = group['created_by'] == currentUser?['id'];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(
            groupId: group['id'],
            currentUser: currentUser,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Venue image or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: group['venue_image'] != null
                  ? Image.network(
                      group['venue_image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(),
                    )
                  : _iconBox(),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name + owner badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(group['name'] ?? 'Group',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('👑 Owner',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Venue name
                  if (group['venue_name'] != null)
                    Row(children: [
                      const Icon(Icons.stadium_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(group['venue_name'],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  const SizedBox(height: 4),

                  // Date + time
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(group['booking_date']?.toString())}  ·  ${_formatTime(group['start_time']?.toString())}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // Member fill bar
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (memberCount / maxMembers).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.divider,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$memberCount/$maxMembers',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.navy.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.groups_rounded,
            color: AppColors.navy, size: 28),
      );
}

// ── My Venues Tab ─────────────────────────────────────────────────────────────

class _MyVenuesTab extends StatelessWidget {
  final Future<List<dynamic>> future;
  final bool isLoggedIn;
  final Future<void> Function() onRefresh;
  const _MyVenuesTab({
    required this.future,
    required this.isLoggedIn,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const _NotLoggedInState(
          message: 'Sign in to see your listed venues');
    }
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _ErrorState(message: 'Error loading venues');
        }
        final venues = snapshot.data ?? [];
        if (venues.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.navy,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: const [
                _EmptyState(
                  icon: Icons.stadium_rounded,
                  title: 'No venues listed',
                  subtitle: 'Venues you create will appear here',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.navy,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: venues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
          ),
        );
      },
    );
  }
}

class _VenueCard extends StatelessWidget {
  final dynamic venue;
  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: Image.network(
              venue['image_url'] ?? '',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.cardBg,
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (venue['address'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(venue['address'],
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text('\$${venue['price']} / session',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _NotLoggedInState extends StatelessWidget {
  final String message;
  const _NotLoggedInState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Not signed in',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)));
  }
}