import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:love_app/core/config/supabase_config.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/notification_service.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:love_app/features/onboarding/presentation/create_profile_screen.dart';
import 'package:love_app/features/onboarding/presentation/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase init notice: $e');
    }
  }

  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: LoveSyncApp(),
    ),
  );
}

class LoveSyncApp extends ConsumerWidget {
  const LoveSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(coupleRepositoryProvider);

    final Widget homeScreen;
    if (repo.hasCompletedOnboarding || repo.hasCreatedProfile) {
      homeScreen = const DashboardScreen();
    } else if (repo.isSignedIn) {
      homeScreen = const CreateProfileScreen();
    } else {
      homeScreen = const WelcomeScreen();
    }

    return MaterialApp(
      title: 'LoveSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeScreen,
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => homeScreen,
      ),
    );
  }
}
