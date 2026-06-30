import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Đăng ký lắng nghe tin nhắn thời gian thực trong một cuộc trò chuyện cụ thể.
  /// Bảng lắng nghe: 'messages'
  RealtimeChannel subscribeToChatMessages({
    required String chatId,
    required void Function(Map<String, dynamic> message) onNewMessage,
  }) {
    log('Đang kết nối Realtime lắng nghe Chat ID: $chatId');

    final channel = _client.channel('chat_room_$chatId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert, // Lắng nghe sự kiện thêm mới tin nhắn
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (PostgresChangePayload payload) {
        log('Phát hiện tin nhắn mới từ Supabase Realtime: ${payload.newRecord}');
        onNewMessage(payload.newRecord);
      },
    ).subscribe((status, [error]) {
      log('Trạng thái kết nối Realtime Chat: $status ${error != null ? "- Lỗi: $error" : ""}');
    });

    return channel;
  }

  /// Đăng ký lắng nghe thông báo thời gian thực dành cho một người dùng nhất định.
  /// Bảng lắng nghe: 'notifications'
  RealtimeChannel subscribeToUserNotifications({
    required String userId,
    required void Function(Map<String, dynamic> notification) onNewNotification,
  }) {
    log('Đang kết nối Realtime lắng nghe thông báo của User ID: $userId');

    final channel = _client.channel('user_notifications_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (PostgresChangePayload payload) {
        log('Phát hiện thông báo mới từ Supabase Realtime: ${payload.newRecord}');
        onNewNotification(payload.newRecord);
      },
    ).subscribe((status, [error]) {
      log('Trạng thái kết nối Realtime Notification: $status ${error != null ? "- Lỗi: $error" : ""}');
    });

    return channel;
  }

  /// Hủy đăng ký lắng nghe (khi rời màn hình Chat hoặc đăng xuất)
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
    log('Đã huỷ kết nối Realtime Channel');
  }
}
