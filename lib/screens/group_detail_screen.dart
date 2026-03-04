import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import 'group_chat_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic>? currentUser;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.currentUser,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<Map<String, dynamic>> _groupFuture;

  @override
  void initState() {
    super.initState();
    _groupFuture = ApiService.getGroup(widget.groupId);
  }

  void _load() {
    final future = ApiService.getGroup(widget.groupId);
    if (mounted) setState(() => _groupFuture = future);
  }

  bool _isMember(Map<String, dynamic> group) {
    final userId = widget.currentUser?['id'];
    if (userId == null) return false;
    final members = group['members'] as List<dynamic>? ?? [];
    return members.any((m) => m['id'] == userId);
  }

  bool _isCreator(Map<String, dynamic> group) =>
      group['created_by'] == widget.currentUser?['id'];

  Future<void> _join(Map<String, dynamic> group) async {
    final userId = widget.currentUser?['id'] as int?;
    if (userId == null) return;
    try {
      await ApiService.joinGroup(widget.groupId, userId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('You joined the group!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _leave() async {
    final userId = widget.currentUser?['id'] as int?;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Group',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.leaveGroup(widget.groupId, userId);
      _load();
    } catch (_) {}
  }

  void _openChat(Map<String, dynamic> group) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GroupChatScreen(
        groupId: widget.groupId,
        groupName: group['name'] ?? 'Group Chat',
        currentUser: widget.currentUser,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading group'));
          }
          final group = snapshot.data!;
          final members = group['members'] as List<dynamic>? ?? [];
          final memberCount = members.length;
          final maxMembers = group['max_members'] ?? 10;
          final isMember = _isMember(group);
          final isCreator = _isCreator(group);
          final isFull = memberCount >= maxMembers;

          return CustomScrollView(
            slivers: [

              // ── Hero image + header overlay ───────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      // Venue image
                      group['venue_image'] != null
                          ? Image.network(
                              group['venue_image'],
                              width: double.infinity,
                              height: 280,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.navyLight,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.white38, size: 48),
                              ),
                            )
                          : Container(
                              color: AppColors.navy,
                              width: double.infinity,
                              height: 280,
                            ),

                      // Dark gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 1.0],
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                                Colors.black.withOpacity(0.72),
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
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16),
                          ),
                        ),
                      ),

                      // Leave button top right
                      if (isMember && !isCreator)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 16,
                          child: GestureDetector(
                            onTap: _leave,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Leave',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),

                      // Group info overlaid at bottom of image
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Venue name pill
                            if (group['venue_name'] != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stadium_rounded,
                                        size: 12, color: AppColors.navy),
                                    const SizedBox(width: 5),
                                    Text(group['venue_name'],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy)),
                                  ],
                                ),
                              ),

                            // Group name
                            Text(group['name'] ?? 'Group',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black54,
                                          blurRadius: 8)
                                    ])),

                            if (group['description'] != null &&
                                group['description'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(group['description'],
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.8),
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),

                            const SizedBox(height: 10),

                            // Slot chips row
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _HeaderChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: group['booking_date']
                                            ?.toString()
                                            .substring(0, 10) ??
                                        '—'),
                                _HeaderChip(
                                    icon: Icons.schedule_rounded,
                                    label: _formatTime(group['start_time']
                                        ?.toString())),
                                _HeaderChip(
                                    icon: Icons.timer_rounded,
                                    label:
                                        '${group['duration_hours']} ${group['duration_hours'] == 1 ? 'hr' : 'hrs'}'),
                                _HeaderChip(
                                    icon: Icons.people_rounded,
                                    label:
                                        '$memberCount / $maxMembers'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Venue detail card ────────────────────────────
              if (group['venue_name'] != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.navy.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Thumb
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: group['venue_image'] != null
                                ? Image.network(
                                    group['venue_image'],
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _venuePlaceholder(),
                                  )
                                : _venuePlaceholder(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(group['venue_name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                                if (group['venue_address'] != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 3),
                                    child: Row(children: [
                                      const Icon(
                                          Icons.location_on_rounded,
                                          size: 11,
                                          color: AppColors.gold),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                            group['venue_address'],
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary),
                                            overflow:
                                                TextOverflow.ellipsis),
                                      ),
                                    ]),
                                  ),
                              ],
                            ),
                          ),
                          if (group['venue_price'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${double.tryParse(group['venue_price'].toString())?.toStringAsFixed(0) ?? group['venue_price']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppColors.navy),
                                ),
                                const Text('/hr',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Members section ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Members',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3)),
                      // Fill bar
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (memberCount / maxMembers)
                                    .clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                color: isFull
                                    ? AppColors.error
                                    : AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$memberCount/$maxMembers',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Members list ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final m = members[i];
                      final isOwner = m['id'] == group['created_by'];
                      return _MemberTile(
                          member: m, isOwner: isOwner);
                    },
                    childCount: members.length,
                  ),
                ),
              ),

              // ── Empty members state ───────────────────────────
              if (members.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(children: [
                      const Icon(Icons.group_off_rounded,
                          color: AppColors.textMuted, size: 40),
                      const SizedBox(height: 8),
                      const Text('No members yet',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14)),
                    ]),
                  ),
                ),

              // ── Action buttons ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    children: [
                      // Chat button — always visible for members
                      if (isMember)
                        _ActionButton(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Group Chat',
                          color: AppColors.navy,
                          onTap: () => _openChat(group),
                        ),

                      if (isMember) const SizedBox(height: 12),

                      // Join button — for non-members
                      if (!isMember)
                        _ActionButton(
                          icon: isFull
                              ? Icons.block_rounded
                              : Icons.group_add_rounded,
                          label: isFull ? 'Group is Full' : 'Join Group',
                          color: isFull ? AppColors.textMuted : AppColors.gold,
                          textColor: isFull ? Colors.white : AppColors.navy,
                          onTap: isFull ? null : () => _join(group),
                        ),
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

  Widget _venuePlaceholder() => Container(
        width: 56,
        height: 56,
        color: AppColors.navyLight,
        child: const Icon(Icons.stadium_rounded,
            color: Colors.white54, size: 24),
      );

  String _formatTime(String? t) {
    if (t == null) return '—';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    return '$h12:$m $suffix';
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final dynamic member;
  final bool isOwner;
  const _MemberTile({required this.member, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final name = member['name'] ?? 'Unknown';
    final avatarUrl = member['avatar_url'];
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navy.withOpacity(0.1),
              border: isOwner
                  ? Border.all(color: AppColors.gold, width: 2.5)
                  : null,
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(initials,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.navy)))
                : null,
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
          ),

          // Owner / member badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOwner
                  ? AppColors.gold.withOpacity(0.15)
                  : AppColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOwner ? '👑 Owner' : 'Member',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isOwner ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.divider : color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onTap == null ? Colors.white54 : textColor,
                size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? Colors.white54 : textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Header chip ───────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

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
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}