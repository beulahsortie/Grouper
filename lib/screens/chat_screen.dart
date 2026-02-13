import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: ApiService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading conversations'));
          }
          final conversations = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: conversations.length,
            itemBuilder: (c, i) {
              final conv = conversations[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatConversationScreen(conversationId: conv['id'], conversationName: conv['name']),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(conv['avatar_url'] ?? ''),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conv['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Tap to view conversation'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
          );
        },
      ),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final int conversationId;
  final String conversationName;
  ChatConversationScreen({required this.conversationId, required this.conversationName});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  List<dynamic> _messages = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final msgs = await ApiService.getMessages(widget.conversationId);
    setState(() => _messages = msgs);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversationName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (c, i) {
                  final m = _messages[i];
                  final isMe = m['sender_id'] == 1; // Demo: userId=1
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.black : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Text(
                        m['text'] ?? '',
                        style: TextStyle(color: isMe ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      await ApiService.sendMessage(widget.conversationId, 1, text); // Demo: sender_id=1
                      _controller.clear();
                      await _fetchMessages();
                    },
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation {
  final String name;
  final String avatar;
  _Conversation({required this.name, required this.avatar});
}

class _Message {
  final String text;
  final bool isMe;
  _Message({required this.text, required this.isMe});
}
