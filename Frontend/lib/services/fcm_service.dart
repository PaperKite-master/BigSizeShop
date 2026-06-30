import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Nhận tin nhắn background: ${message.messageId}");
  debugPrint("Tiêu đề: ${message.notification?.title}");
  debugPrint("Nội dung: ${message.notification?.body}");
  debugPrint("Dữ liệu kèm theo (data): ${message.data}");
}

class FcmService {
  FcmService._internal();
  static final FcmService instance = FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Khởi tạo cấu hình FCM
  Future<void> initialize({
    Future<void> Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
  }) async {
    if (_isInitialized) return;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Trạng thái cấp quyền thông báo: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // 2. Lấy FCM Token phục vụ cho việc gửi thông báo từ backend
      String? token = await _messaging.getToken();
      debugPrint('FCM Token hiện tại: $token');
      if (token != null && onTokenRefresh != null) {
        await onTokenRefresh(token);
      }

      // 3. Lắng nghe khi token thay đổi/làm mới
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token mới được cập nhật: $newToken');
        if (onTokenRefresh != null) {
          await onTokenRefresh(newToken);
        }
      });

      // 4. Lắng nghe tin nhắn khi app đang mở ở FOREGROUND (Màn hình chính)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Nhận tin nhắn khi ứng dụng đang mở (Foreground): ${message.messageId}');
        if (onForegroundMessage != null) {
          onForegroundMessage(message);
        } else {
          // Xử lý mặc định: Hiển thị hộp thoại hoặc cập nhật UI
          _defaultForegroundHandler(message);
        }
      });

      // 5. Đăng ký hàm xử lý khi app chạy dưới BACKGROUND hoặc bị TERMINATED
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 6. Xử lý khi người dùng nhấn vào thông báo để mở app từ trạng thái BACKGROUND
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Người dùng nhấn vào thông báo từ Background: ${message.data}');
        if (onMessageOpenedApp != null) {
          onMessageOpenedApp(message);
        }
      });

      // 7. Xử lý khi người dùng nhấn vào thông báo để mở app từ trạng thái TERMINATED (Tắt hẳn)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Ứng dụng được mở từ thông báo ở trạng thái tắt hẳn (Terminated): ${initialMessage.data}');
        if (onMessageOpenedApp != null) {
          onMessageOpenedApp(initialMessage);
        }
      }

      _isInitialized = true;
    }
  }

  void _defaultForegroundHandler(RemoteMessage message) {
    debugPrint("Tiêu đề Foreground: ${message.notification?.title}");
    debugPrint("Nội dung Foreground: ${message.notification?.body}");
  }
}
