import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GroupChatScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final Map<String, dynamic>? currentUser;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _sending = false;
  bool _initialLoad = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll every 4 seconds for new messages
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await ApiService.getGroupMessages(widget.groupId);
      if (!mounted) return;
      final wasAtBottom = _isAtBottom();
      setState(() {
        _messages = msgs;
        _initialLoad = false;
      });
      // Auto-scroll only if user was already at the bottom
      if (wasAtBottom) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) setState(() => _initialLoad = false);
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    return (max - current) < 80;
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    final userId = widget.currentUser?['id'] as int?;
    if (text.isEmpty || userId == null || _sending) return;

    _messageController.clear();
    setState(() => _sending = true);

    try {
      await ApiService.sendGroupMessage(widget.groupId, userId, text);
      await _fetchMessages();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      // Restore text if send failed
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.currentUser?['id'];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 18,
            ),
            child: Row(
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
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: AppColors.navy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.groupName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text('${_messages.length} messages',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Messages list ─────────────────────────────────────
          Expanded(
            child: _initialLoad
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _EmptyChat(
                        name: widget.currentUser?['name'] ?? 'you')
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg['sender_id'] == myId;
                          final showAvatar = !isMe &&
                              (i == 0 ||
                                  _messages[i - 1]['sender_id'] !=
                                      msg['sender_id']);
                          final showName = showAvatar;
                          final isLast = i == _messages.length - 1 ||
                              _messages[i + 1]['sender_id'] !=
                                  msg['sender_id'];

                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            showAvatar: showAvatar,
                            showName: showName,
                            isLast: isLast,
                          );
                        },
                      ),
          ),

          // ── Input bar ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 12,
              top: 10,
              bottom:
                  MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.navy.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _sending
                          ? AppColors.navy.withOpacity(0.5)
                          : AppColors.navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;
  final bool isLast;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final name = message['sender_name'] ?? '';
    final text = message['text'] ?? '';
    final avatarUrl = message['avatar_url'];
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final time = _formatTime(message['created_at']?.toString());

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 12 : 3,
        top: showName ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user avatar
          if (!isMe)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy.withOpacity(0.1),
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: avatarUrl == null
                          ? Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy)))
                          : null,
                    )
                  : const SizedBox(width: 34),
            ),

          if (!isMe) const SizedBox(width: 8),

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.4)),
                ),
                if (isLast)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(time,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.navy, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Say hi to your group, $name!',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}