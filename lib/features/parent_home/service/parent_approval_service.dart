import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';

class ParentApprovalService {
  const ParentApprovalService({
    required this.userContextRepository,
    required this.tabungRequestRepository,
    required this.tabungRepository,
  });

  final UserContextRepository userContextRepository;
  final TabungRequestRepository tabungRequestRepository;
  final TabungRepository tabungRepository;

  Future<void> approve({required String requestId, required String tabungId, String? response}) async {
    final submissionContext = await userContextRepository.resolveSubmissionContext(UserRole.parent);
    await tabungRequestRepository.approveRequest(requestId: requestId, parentResponse: response ?? 'Approved by parent');
    await tabungRepository.approveTabung(
      tabungId: tabungId,
      parentId: submissionContext.userId,
      parentResponse: response ?? 'Approved by parent',
    );
  }

  Future<void> reject({required String requestId, required String tabungId, required String reason}) async {
    await tabungRequestRepository.rejectRequest(requestId: requestId, parentResponse: reason);
    await tabungRepository.rejectTabung(tabungId: tabungId, rejectedReason: reason);
  }
}
