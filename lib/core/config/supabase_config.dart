import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iaogyirgnpojofjvxxse.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlhb2d5aXJnbnBvam9manZ4eHNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE1MTYsImV4cCI6MjEwNzM5NzUxNn0.bQd8Xe8Iu7oUGNyO_Q4AHRqFJnJuOPQcQE5Cttrf1XE',
  );

  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT_REF') && !anonKey.contains('YOUR_SUPABASE_ANON_KEY');

  static bool get isInitialized {
    if (!isConfigured) return false;
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? get client {
    if (isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}

