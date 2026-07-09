import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/supabase_realtime_service.dart';
import 'app_providers.dart';

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.watch(apiClientProvider)),
);

final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>(
  (ref) => SupabaseRealtimeService(),
);

final chatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  return ref.watch(chatServiceProvider).listChats();
});

final chatMessagesProvider = FutureProvider.family<List<MessageModel>, String>(
  (ref, chatId) async {
    return ref.watch(chatServiceProvider).listMessages(chatId);
  },
);
