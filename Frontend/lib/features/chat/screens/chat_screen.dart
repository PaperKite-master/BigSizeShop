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

  Future<void> _startChat() async {
    if (_isOpeningChat) return;

    setState(() => _isOpeningChat = true);

    try {
      final chat = await ref.read(chatServiceProvider).openChat();
      if (mounted) {
        context.go('/chat/${chat.id}');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ trò chuyện'),
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
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            );
          }

          return chatsAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(message: error.toString()),
            data: (chats) {
              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.isAdmin
                            ? 'Chưa có khách hàng nào liên hệ.'
                            : 'Chưa có cuộc trò chuyện nào.',
                      ),
                      const SizedBox(height: 16),
                      if (!user.isAdmin)
                        FilledButton(
                          onPressed: _isOpeningChat ? null : _startChat,
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
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(chatsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final title = user.isAdmin
                        ? chat.customer?.fullName ?? 'Khách hàng'
                        : 'Hỗ trợ BigSize Shop';
                    final subtitle =
                        chat.lastMessage?.content ?? 'Chưa có tin nhắn';

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      leading: const CircleAvatar(
                        child: Icon(Icons.support_agent),
                      ),
                      title: Text(title),
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
              );
            },
          );
        },
      ),
      floatingActionButton: authState.maybeWhen(
        data: (user) {
          if (user == null || user.isAdmin) return null;

          return FloatingActionButton.extended(
            onPressed: _isOpeningChat ? null : _startChat,
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
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  RealtimeChannel? _realtimeChannel;
  final List<MessageModel> _liveMessages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _unsubscribeFromRealtime();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _unsubscribeFromRealtime() async {
    final channel = _realtimeChannel;
    _realtimeChannel = null;

    if (channel != null) {
      await ref.read(supabaseRealtimeServiceProvider).unsubscribe(channel);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện'),
      ),
      body: Column(
        children: [
          if (!SupabaseConfig.isConfigured)
            MaterialBanner(
              content: const Text(
                'Supabase chưa được cấu hình. Tin nhắn gửi qua API vẫn hoạt động, '
                'nhưng Realtime sẽ không cập nhật tự động.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
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
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
