import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';
import 'group_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  const ChatScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Keyed by userId so a fresh future is created whenever the user changes
  int? _loadedForUserId;
  Future<List<dynamic>>? _groupsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfNeeded();
  }

  void _refreshIfNeeded() {
    final uid = widget.currentUser?['id'];
    if (uid != null && uid != _loadedForUserId) {
      _loadedForUserId = uid;
      _groupsFuture = ApiService.getUserGroups(uid);
    } else if (uid == null && _loadedForUserId != null) {
      _loadedForUserId = null;
      _groupsFuture = null;
    }
  }

  void _reload() {
    final uid = widget.currentUser?['id'];
    if (uid == null) return;
    setState(() {
      _loadedForUserId = uid;
      _groupsFuture = ApiService.getUserGroups(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
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
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Group Chats',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.7)),
                const SizedBox(height: 4),
                Text(
                  widget.currentUser != null
                      ? 'Your active group conversations'
                      : 'Sign in to see your groups',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: widget.currentUser == null
                ? _NotLoggedIn()
                : FutureBuilder<List<dynamic>>(
                    future: _groupsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        );
                      }
                      final groups = snapshot.data ?? [];

                      if (groups.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async => _reload(),
                          color: AppColors.navy,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 40, 20, 100),
                            children: [
                              Column(children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.navy.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: AppColors.textMuted,
                                      size: 36),
                                ),
                                const SizedBox(height: 16),
                                const Text('No group chats yet',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                const Text(
                                    'Join or create a group to start chatting',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                              ]),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _reload(),
                        color: AppColors.navy,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _GroupChatTile(
                            group: groups[i],
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Group chat tile ───────────────────────────────────────────────────────────

class _GroupChatTile extends StatelessWidget {
  final dynamic group;
  final Map<String, dynamic>? currentUser;
  const _GroupChatTile({required this.group, this.currentUser});

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
    return d.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final name = group['name'] ?? 'Group';
    final venueName = group['venue_name'] ?? '';
    final memberCount = group['member_count'] ?? 0;
    final maxMembers = group['max_members'] ?? 10;
    final isOwner = group['created_by'] == currentUser?['id'];
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupChatScreen(
            groupId: group['id'],
            groupName: name,
            currentUser: currentUser,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
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
                  const SizedBox(height: 3),
                  if (venueName.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.stadium_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(venueName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatDate(group['booking_date']?.toString())}  ·  ${_formatTime(group['start_time']?.toString())}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      const Icon(Icons.people_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text('$memberCount/$maxMembers',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.navy, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Not logged in ─────────────────────────────────────────────────────────────

class _NotLoggedIn extends StatelessWidget {
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
          const Text('Sign in to access your group chats',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}