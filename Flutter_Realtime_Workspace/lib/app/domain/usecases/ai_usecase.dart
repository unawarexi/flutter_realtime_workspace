import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/ai_provider.dart';

/// Business logic for the AI Assistant feature.
///
/// Handles RBAC gating for chat, RAG, and tool execution.
/// All network calls go through [aiRepositoryProvider]; errors surface
/// via [AppToast] so the UI stays logic-free.
class AIUseCase {
  AIUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canChat(WidgetRef ref) =>
      PermissionHelper.canUseAI(_level(ref));

  static bool canUseRAG(WidgetRef ref) =>
      PermissionHelper.canUseRAG(_level(ref));

  static bool canExecuteTools(WidgetRef ref) =>
      PermissionHelper.canExecuteAITools(_level(ref));

  // ── Chat ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> sendMessage({
    required BuildContext context,
    required WidgetRef ref,
    required String message,
    String? conversationId,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
      };
      final result = await ref.read(aiRepositoryProvider).chat(body);
      return result;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  // ── Conversations ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getConversations(
      WidgetRef ref) async {
    try {
      return await ref.read(aiRepositoryProvider).getConversations();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getConversation(
      WidgetRef ref, String id) async {
    try {
      return await ref.read(aiRepositoryProvider).getConversation(id);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteConversation({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(aiRepositoryProvider).deleteConversation(id);
      if (context.mounted) {
        AppToast.show(
          'Conversation deleted',
          type: ToastType.success,
          context: context,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
  }

  // ── RAG ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> ragQuery({
    required BuildContext context,
    required WidgetRef ref,
    required String query,
    String? collection,
  }) async {
    try {
      final body = <String, dynamic>{
        'query': query,
        if (collection != null) 'collection': collection,
      };
      return await ref.read(aiRepositoryProvider).ragQuery(body);
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> ragIngest({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final result = await ref.read(aiRepositoryProvider).ragIngest(body);
      if (context.mounted) {
        AppToast.show(
          'Documents ingested successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  // ── Tools ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> executeTool({
    required BuildContext context,
    required WidgetRef ref,
    required String toolName,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      final result =
          await ref.read(aiRepositoryProvider).executeTool(toolName, parameters);
      if (context.mounted) {
        AppToast.show(
          'Tool executed: $toolName',
          type: ToastType.success,
          context: context,
        );
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  // ── Summarize ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> summarize({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      return await ref.read(aiRepositoryProvider).summarize(body);
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
