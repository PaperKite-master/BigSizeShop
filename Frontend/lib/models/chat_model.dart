import 'user_model.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.sentAt,
    this.sender,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime? sentAt;
  final UserModel? sender;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'] ?? json['users'];

    return MessageModel(
      id: json['id'] as String,
      chatId: (json['chatId'] ?? json['chat_id']) as String,
      senderId: (json['senderId'] ?? json['sender_id']) as String,
      content: json['content'] as String,
      sentAt: _parseDate(json['sentAt'] ?? json['sent_at']),
      sender: senderJson is Map<String, dynamic>
          ? UserModel.fromJson(senderJson)
          : null,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ChatModel {
  const ChatModel({
    required this.id,
    required this.customerId,
    this.adminId,
    this.createdAt,
    this.customer,
    this.admin,
    this.lastMessage,
  });

  final String id;
  final String customerId;
  final String? adminId;
  final DateTime? createdAt;
  final UserModel? customer;
  final UserModel? admin;
  final MessageModel? lastMessage;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      customerId: (json['customerId'] ?? json['customer_id']) as String,
      adminId: json['adminId'] as String? ?? json['admin_id'] as String?,
      createdAt: MessageModel._parseDate(json['createdAt'] ?? json['created_at']),
      customer: json['customer'] is Map<String, dynamic>
          ? UserModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      admin: json['admin'] is Map<String, dynamic>
          ? UserModel.fromJson(json['admin'] as Map<String, dynamic>)
          : null,
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }
}
