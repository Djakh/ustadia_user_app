/// Typed contracts for safety reports.
///
/// The mobile app currently has no report endpoint exposed by the backend, so
/// these contracts are intentionally not wired to a fake implementation.
enum ProfileReportReason {
  inappropriateImage,
  personalInformation,
  harassmentOrImpersonation,
  other,
}

enum AiResponseReportReason {
  inappropriateContent,
  incorrectOrMisleadingResponse,
  unsafeAdvice,
  other,
}

abstract interface class ProfileReportRepository {
  Future<void> reportProfile({
    required String userId,
    required ProfileReportReason reason,
    String? details,
  });
}

abstract interface class AiResponseReportRepository {
  Future<void> reportResponse({
    required String messageId,
    required AiResponseReportReason reason,
    String? details,
  });
}
