import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

abstract class DashboardRepository {
  Future<DashboardData> loadDashboard(UserRole role);
  Future<void> signOut();
}
