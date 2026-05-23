class GoalPlannerException implements Exception {
  const GoalPlannerException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'GoalPlannerException(code: $code, message: $message)';
}
