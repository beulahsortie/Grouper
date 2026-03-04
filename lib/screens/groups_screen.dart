import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  final int venueId;
  final String venueName;
  final String date;
  final String startTime;
  final String displayTime;
  final int durationHours;
  final Map<String, dynamic>? currentUser;

  const GroupsScreen({
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
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<dynamic>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _groupsFuture = ApiService.getGroups(
        venueId: widget.venueId,
        date: widget.date,
        startTime: widget.startTime,
      );
    });
  }

  Future<void> _join(int groupId) async {
    final userId = widget.currentUser?['id'] as int?;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join a group')),
      );
      return;
    }
    try {
      await ApiService.joinGroup(groupId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Joined successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Stack(
        children:[Column(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Groups',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text(widget.venueName,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Slot summary chips
                Row(
                  children: [
                    _Chip(
                        icon: Icons.calendar_today_rounded,
                        label: widget.date),
                    const SizedBox(width: 8),
                    _Chip(
                        icon: Icons.schedule_rounded,
                        label: widget.displayTime),
                    const SizedBox(width: 8),
                    _Chip(
                        icon: Icons.timer_rounded,
                        label:
                            '${widget.durationHours} ${widget.durationHours == 1 ? 'hr' : 'hrs'}'),
                  ],
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _groupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading groups'));
                }
                final groups = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.navy,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => _GroupCard(
                      group: groups[i],
                      currentUserId:
                          widget.currentUser?['id'] as int?,
                      onJoin: () => _join(groups[i]['id']),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            groupId: groups[i]['id'],
                            currentUser: widget.currentUser,
                          ),
                        ),
                      ).then((_) => _load()),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB: Create new group ──────────────────────────────────
      Positioned(
        bottom: 24,
        right: 20,
        child: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateGroupScreen(
                venueId: widget.venueId,
                venueName: widget.venueName,
                date: widget.date,
                startTime: widget.startTime,
                displayTime: widget.displayTime,
                durationHours: widget.durationHours,
                currentUser: widget.currentUser,
              ),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
        label: const Text('Create Group',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      )]
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  final int? currentUserId;
  final VoidCallback onJoin;
  final VoidCallback? onTap;
  const _GroupCard({
    required this.group,
    required this.currentUserId,
    required this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final memberCount = group['member_count'] ?? 0;
    final maxMembers = group['max_members'] ?? 10;
    final isFull = memberCount >= maxMembers;
    final fillPercent = memberCount / maxMembers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppColors.navy, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group['name'] ?? 'Group',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    if (group['description'] != null &&
                        group['description'].toString().isNotEmpty)
                      Text(group['description'],
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Full',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error)),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Member count + progress bar
          Row(
            children: [
              const Icon(Icons.people_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('$memberCount / $maxMembers members',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPercent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: isFull ? AppColors.error : AppColors.navy,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFull ? null : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(isFull ? 'Group Full' : 'Join Group',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
