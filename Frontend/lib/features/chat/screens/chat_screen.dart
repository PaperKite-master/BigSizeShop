import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/chat_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/chat_providers.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _isOpeningChat = false;
  String _searchQuery = '';
  String? _selectedChatId;

  // Van Gogh Colors
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);

  Future<void> _startChat() async {
    if (_isOpeningChat) return;

    setState(() => _isOpeningChat = true);

    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      final chat = await ref.read(chatServiceProvider).openChat();
      if (mounted) {
        if (user != null && user.isAdmin && MediaQuery.sizeOf(context).width > 800) {
          setState(() {
            _selectedChatId = chat.id;
          });
        } else {
          context.go('/chat/${chat.id}');
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final chatsAsync = ref.watch(chatsProvider);
    final isWideScreen = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Hỗ trợ khách hàng',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
        backgroundColor: vgMidnight,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vui lòng đăng nhập để sử dụng chat.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(backgroundColor: vgStarGold, foregroundColor: vgMidnight),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            );
          }

          final bool isAdmin = user.isAdmin;

          return chatsAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(message: error.toString()),
            data: (chats) {
              final filteredChats = chats.where((chat) {
                final name = (isAdmin
                        ? chat.customer?.fullName
                        : 'Hỗ trợ BigSize Shop') ??
                    '';
                return name.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (isAdmin && isWideScreen) {
                return _buildSplitPaneLayout(filteredChats, chats, user);
              }

              return _buildStandardListLayout(filteredChats, chats, user);
            },
          );
        },
      ),
      floatingActionButton: authState.maybeWhen(
        data: (user) {
          if (user == null || user.isAdmin) return null;

          return FloatingActionButton.extended(
            onPressed: _isOpeningChat ? null : _startChat,
            backgroundColor: vgStarGold,
            foregroundColor: vgMidnight,
            icon: _isOpeningChat
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat),
            label: const Text('Chat mới'),
          );
        },
        orElse: () => null,
      ),
    );
  }

  // 🖥️ Web Admin Split-Pane layout
  Widget _buildSplitPaneLayout(List<ChatModel> filteredChats, List<ChatModel> allChats, var user) {
    return Row(
      children: [
        // Left Column: Chat history & stats
        SizedBox(
          width: 350,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Quick Admin Stats Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: vgMidnight.withOpacity(0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Tổng cuộc gọi', '${allChats.length}', Icons.forum_outlined),
                      _buildStatItem(
                        'Chờ hỗ trợ',
                        '${allChats.where((c) => c.lastMessage != null).length}',
                        Icons.mark_chat_unread_outlined,
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm khách hàng...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Chats List
                Expanded(
                  child: filteredChats.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Chưa có khách hàng nào liên hệ.'
                                : 'Không tìm thấy kết quả.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredChats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            final isSelected = _selectedChatId == chat.id;
                            final customerName = chat.customer?.fullName ?? 'Khách hàng';
                            final lastMsg = chat.lastMessage?.content ?? 'Chưa có tin nhắn';

                            return ListTile(
                              selected: isSelected,
                              selectedColor: vgMidnight,
                              selectedTileColor: vgCyanSky.withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? vgStarGold : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? vgStarGold : vgMidnight.withOpacity(0.1),
                                foregroundColor: isSelected ? vgMidnight : vgMidnight,
                                child: const Icon(Icons.person),
                              ),
                              title: Text(
                                customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedChatId = chat.id;
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Embedded chat window
        Expanded(
          child: _selectedChatId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.headset_mic_outlined, size: 64, color: vgCyanSky.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Chọn một cuộc trò chuyện để bắt đầu hỗ trợ khách hàng',
                        style: TextStyle(
                          color: vgMidnight.withOpacity(0.6),
                          fontSize: 16,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Các tin nhắn mới sẽ cập nhật trong thời gian thực.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: Colors.white,
                  child: ChatScreen(
                    key: ValueKey(_selectedChatId),
                    chatId: _selectedChatId!,
                    embed: true,
                  ),
                ),
        ),
      ],
    );
  }

  // 📱 Standard Mobile Layout
  Widget _buildStandardListLayout(List<ChatModel> filteredChats, List<ChatModel> allChats, var user) {
    final bool isAdmin = user.isAdmin;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: isAdmin ? 'Tìm khách hàng...' : 'Tìm đoạn hội thoại...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        // List content
        Expanded(
          child: filteredChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAdmin
                            ? 'Chưa có khách hàng nào liên hệ.'
                            : 'Chưa có cuộc trò chuyện nào.',
                      ),
                      const SizedBox(height: 16),
                      if (!isAdmin)
                        FilledButton(
                          onPressed: _isOpeningChat ? null : _startChat,
                          style: FilledButton.styleFrom(backgroundColor: vgStarGold, foregroundColor: vgMidnight),
                          child: _isOpeningChat
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Bắt đầu chat với hỗ trợ'),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(chatsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredChats.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final title = isAdmin
                          ? chat.customer?.fullName ?? 'Khách hàng'
                          : 'Hỗ trợ BigSize Shop';
                      final subtitle = chat.lastMessage?.content ?? 'Chưa có tin nhắn';

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: vgMidnight.withOpacity(0.1),
                          foregroundColor: vgMidnight,
                          child: Icon(isAdmin ? Icons.person_outline : Icons.support_agent),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/chat/${chat.id}'),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: vgCyanSky),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: vgMidnight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    this.embed = false,
  });

  final String chatId;
  final bool embed;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  RealtimeChannel? _realtimeChannel;
  final List<MessageModel> _liveMessages = [];
  bool _isSending = false;
  bool _showSupabaseBanner = true;

  final List<String> _quickReplies = [
    'Xin chào! BigSize Shop có thể giúp gì cho bạn?',
    'Đơn hàng của bạn đang được đóng gói và bàn giao vận chuyển.',
    'Sản phẩm này hiện đang tạm hết hàng, bạn có muốn xem mẫu khác không?',
    'Cảm ơn bạn đã liên hệ. Shop xin đóng cuộc hội thoại này nhé!',
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    final channel = _realtimeChannel;
    _realtimeChannel = null;

    if (channel != null) {
      ref.read(supabaseRealtimeServiceProvider).unsubscribe(channel);
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToRealtime() {
    if (!SupabaseConfig.isConfigured) return;

    final realtimeService = ref.read(supabaseRealtimeServiceProvider);

    _realtimeChannel = realtimeService.subscribeToChatMessages(
      chatId: widget.chatId,
      onNewMessage: (record) {
        final message = MessageModel.fromJson(record);

        if (_liveMessages.any((item) => item.id == message.id)) {
          return;
        }

        setState(() {
          _liveMessages.add(message);
        });
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await ref.read(chatServiceProvider).sendMessage(
            chatId: widget.chatId,
            content: content,
          );

      _messageController.clear();

      if (!_liveMessages.any((item) => item.id == message.id)) {
        setState(() {
          _liveMessages.add(message);
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  List<MessageModel> _mergeMessages(List<MessageModel> initialMessages) {
    MessageModel pickPreferred(MessageModel existing, MessageModel incoming) {
      if (existing.sender != null && incoming.sender == null) {
        return existing;
      }
      if (incoming.sender != null && existing.sender == null) {
        return incoming;
      }
      return incoming;
    }

    final merged = <String, MessageModel>{};

    for (final message in initialMessages) {
      merged[message.id] = message;
    }

    for (final message in _liveMessages) {
      final existing = merged[message.id];
      merged[message.id] = existing == null
          ? message
          : pickPreferred(existing, message);
    }

    final result = merged.values.toList()
      ..sort((a, b) {
        final aTime = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUserId = authState.value?.id;
    final isAdmin = authState.value?.isAdmin ?? false;

    Widget buildChatContent() {
      return Column(
        children: [
          if (!SupabaseConfig.isConfigured && _showSupabaseBanner)
            MaterialBanner(
              content: const Text(
                'Supabase chưa được cấu hình. Tin nhắn gửi qua API vẫn hoạt động, '
                'nhưng Realtime sẽ không cập nhật tự động.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSupabaseBanner = false;
                    });
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (initialMessages) {
                final messages = _mergeMessages(initialMessages);

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Hãy gửi tin nhắn đầu tiên.'),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUserId;

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? (isAdmin
                                  ? const Color(0xFFF3C63F).withOpacity(0.2)
                                  : Theme.of(context).colorScheme.primaryContainer)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: isMine && isAdmin
                              ? Border.all(color: const Color(0xFFF3C63F), width: 1)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMine && message.sender != null)
                              Text(
                                message.sender!.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            Text(message.content),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Quick Replies templates for admin
          if (isAdmin)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _quickReplies.map((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          reply,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF0F1E36),
                            fontFamily: 'serif',
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: const Color(0xFF1C528B).withOpacity(0.3)),
                        onPressed: () {
                          _messageController.text = reply;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1E36),
                      foregroundColor: const Color(0xFFF3C63F),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF3C63F)),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (widget.embed) {
      return buildChatContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F1E36),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat'),
        ),
      ),
      body: buildChatContent(),
    );
  }
}
