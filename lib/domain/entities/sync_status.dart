/// Sync status for AI-assisted quick capture.
/// Controls race conditions when user edits during AI processing.
enum SyncStatus {
  /// Awaiting AI classification - user edit will invalidate AI response.
  pendingAi,
  /// AI classification completed and accepted.
  completed,
  /// User manually edited - AI response should be discarded.
  userModified,
}
