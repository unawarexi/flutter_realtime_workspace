import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/subscription_model.dart';
import 'package:flutter_realtime_workspace/store/billing_provider.dart';

/// Business logic for the Billing / Subscription feature.
///
/// Handles subscription viewing, plan changes, and invoice management
/// through [billingRepositoryProvider].
class BillingUseCase {
  BillingUseCase._();

  // ── Subscription ─────────────────────────────────────────────────────────

  static Future<SubscriptionModel?> getSubscription(WidgetRef ref) async {
    try {
      return await ref.read(billingRepositoryProvider).getSubscription();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> changePlan({
    required BuildContext context,
    required WidgetRef ref,
    required String planId,
  }) async {
    try {
      await ref.read(billingRepositoryProvider).updateSubscription({'plan': planId});
      if (context.mounted) {
        AppToast.show(
          'Plan updated successfully',
          type: ToastType.success,
          context: context,
        );
      }
      ref.invalidate(subscriptionProvider);
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

  static Future<bool> cancelSubscription({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(billingRepositoryProvider).updateSubscription({'status': 'cancelled'});
      if (context.mounted) {
        AppToast.show(
          'Subscription cancelled',
          type: ToastType.info,
          context: context,
        );
      }
      ref.invalidate(subscriptionProvider);
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

  // ── Invoices ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getInvoices(WidgetRef ref) async {
    try {
      return await ref.read(billingRepositoryProvider).getInvoices();
    } catch (_) {
      return [];
    }
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String planLabel(String plan) {
    switch (plan) {
      case 'free': return 'Free';
      case 'starter': return 'Starter';
      case 'professional': return 'Professional';
      case 'enterprise': return 'Enterprise';
      default: return plan;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'cancelled': return 'Cancelled';
      case 'past_due': return 'Past Due';
      case 'trialing': return 'Trialing';
      default: return status;
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
