import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

class GoalPlannerInput {
  const GoalPlannerInput({
    required this.userRole,
    required this.tabungType,
    required this.tabungName,
    required this.tabungDescription,
    this.idempotencyKey,
    this.userId,
    this.familyId,
    this.tabungId,
  });

  final UserRole userRole;
  final TabungType tabungType;
  final String tabungName;
  final String tabungDescription;
  final String? idempotencyKey;
  final String? userId;
  final String? familyId;
  final String? tabungId;

  GoalPlannerInput copyWith({
    String? idempotencyKey,
    String? userId,
    String? familyId,
    String? tabungId,
  }) {
    return GoalPlannerInput(
      userRole: userRole,
      tabungType: tabungType,
      tabungName: tabungName,
      tabungDescription: tabungDescription,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      tabungId: tabungId ?? this.tabungId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idempotencyKey': idempotencyKey,
      'userId': userId,
      'familyId': familyId,
      'tabungId': tabungId,
      'userRole': userRole.apiWireValue(),
      'tabungType': tabungType.apiWireValue(),
      'tabungName': tabungName,
      'tabungDescription': tabungDescription,
    };
  }
}
