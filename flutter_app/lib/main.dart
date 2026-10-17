import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'screens/config_error_screen.dart';
import 'services/api.dart';
import 'services/demo_api.dart';
import 'services/supabase_api.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF07070B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final Api api;
  if (Env.demoMode) {
    api = DemoApi();
  } else if (!Env.isConfigured) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const ConfigErrorScreen(),
      ),
    );
    return;
  } else {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    api = SupabaseApi(Supabase.instance.client);
  }

  runApp(AlcoholTrackerApp(api: api));
}
