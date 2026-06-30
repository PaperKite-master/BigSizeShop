import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.resolvedKey,
    );
  }

  try {
    await Firebase.initializeApp();
    await FcmService.instance.initialize(
      onForegroundMessage: (message) {
        debugPrint("Foreground message received: ${message.notification?.title}");
      },
      onMessageOpenedApp: (message) {
        debugPrint("Notification clicked: ${message.data}");
      },
    );
  } catch (e) {
    debugPrint("Firebase/FCM initialization error: $e");
  }

  runApp(const ProviderScope(child: BigSizeShopApp()));
}
