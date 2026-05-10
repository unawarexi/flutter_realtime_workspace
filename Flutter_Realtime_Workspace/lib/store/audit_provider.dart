import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/audit_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/audit_repository.dart';

final auditRepositoryProvider = Provider<AuditRepository>((_) {
  return AuditRepository();
});

final auditLogsProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, Map<String, dynamic>>((ref, filters) {
  return ref.watch(auditRepositoryProvider).getAuditLogs(
        workspaceId: filters['workspaceId'] as String?,
        orgId: filters['orgId'] as String?,
        actorId: filters['actorId'] as String?,
        resourceType: filters['resourceType'] as String?,
        action: filters['action'] as String?,
        from: filters['from'] as DateTime?,
        to: filters['to'] as DateTime?,
      );
});
