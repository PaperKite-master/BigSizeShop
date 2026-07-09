import '../core/network/api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  const ChatService(this._client);

  final ApiClient _client;

  Future<List<ChatModel>> listChats() async {
    final response = await _client.get<Map<String, dynamic>>('/chats');
    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((item) => ChatModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatModel> openChat() async {
    final response = await _client.post<Map<String, dynamic>>('/chats');
    return ChatModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<MessageModel>> listMessages(String chatId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/chats/$chatId/messages',
    );
    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      data: {'content': content},
    );

    return MessageModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
