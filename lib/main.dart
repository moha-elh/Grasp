import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/net.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: Config.supabaseUrl,
    publishableKey: Config.supabaseKey,
    httpClient: resilientHttpClient(),
  );
  await NotificationService.init();
  // Re-arm the daily reminder (Android drops alarms on reboot).
  await NotificationService.rescheduleFromPrefs();
  runApp(const ProviderScope(child: GraspApp()));
}
