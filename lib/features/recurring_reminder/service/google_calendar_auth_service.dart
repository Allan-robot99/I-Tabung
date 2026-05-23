import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final googleCalendarAuthServiceProvider = Provider<GoogleCalendarAuthService>((ref) {
  return SupabaseGoogleCalendarAuthService(ref.watch(supabaseClientProvider));
});

abstract class GoogleCalendarAuthService {
  Future<void> connectGoogleCalendar();
}

class SupabaseGoogleCalendarAuthService implements GoogleCalendarAuthService {
  SupabaseGoogleCalendarAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<void> connectGoogleCalendar() async {
    final response = await _client.functions.invoke(
      'google-calendar-auth-start',
      body: {'redirectUri': 'itabung://google-calendar-auth'},
    );

    final data = response.data;
    if (!(response.status >= 200 && response.status < 300 && data is Map<String, dynamic>)) {
      throw Exception('Unable to start Google Calendar connection.');
    }

    final authUrl = data['authUrl']?.toString();
    if (authUrl == null || authUrl.isEmpty) {
      throw Exception('Google Calendar auth URL is missing.');
    }

    String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'itabung',
      );
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        final connected = await _waitForCalendarConnection();
        if (connected) {
          return;
        }
        throw Exception(
          'Google Calendar sign-in was closed before the app callback finished. '
          'Please try again. If it keeps happening, check that the callback function and deep link are deployed correctly.',
        );
      }
      rethrow;
    }

    final uri = Uri.parse(callback);
    final status = uri.queryParameters['status'];
    if (status != 'success') {
      throw Exception(uri.queryParameters['message'] ?? 'Google Calendar connection was cancelled.');
    }
  }

  Future<bool> _waitForCalendarConnection() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (await _isCalendarConnected()) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isCalendarConnected() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final connectionRows = await _client
        .from('calendar_connections')
        .select('is_connected')
        .eq('user_id', userId)
        .eq('provider', 'google')
        .limit(1);

    if ((connectionRows as List).isEmpty) {
      return false;
    }
    return connectionRows.first['is_connected'] as bool? ?? false;
  }
}
