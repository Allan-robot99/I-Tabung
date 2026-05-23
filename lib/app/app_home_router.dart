import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/auth/view/role_selection_page.dart';
import 'package:i_tabung/features/dashboard/view/dashboard_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppHomeRouter extends ConsumerWidget {
  const AppHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final userContextRepo = ref.watch(userContextRepositoryProvider);

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, client.auth.currentSession),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return const RoleSelectionPage();
        }

        final session = snapshot.data?.session;
        if (session == null) {
          return const RoleSelectionPage();
        }

        return FutureBuilder<UserRole>(
          future: userContextRepo.getCurrentUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (roleSnapshot.hasError) {
              return const RoleSelectionPage();
            }
            final role = roleSnapshot.data;
            if (role == null) {
              return const RoleSelectionPage();
            }
            return DashboardPage(role: role);
          },
        );
      },
    );
  }
}
