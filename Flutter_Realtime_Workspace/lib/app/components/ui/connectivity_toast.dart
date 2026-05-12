import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/store/connectivity_provider.dart';

/// Listens to connectivity changes and fires toasts just below the notch.
/// Drop this anywhere in the widget tree (renders as an empty SizedBox).
class ConnectivityToast extends ConsumerWidget {
  const ConnectivityToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NetworkState>(connectivityProvider, (prev, next) {
      if (next.quality == NetworkQuality.offline) {
        AppToast.show(
          'No internet connection',
          context: context,
          type: ToastType.error,
          durationSeconds: 5,
        );
      } else if (next.quality == NetworkQuality.slow) {
        AppToast.show(
          'Slow network detected',
          context: context,
          type: ToastType.warning,
        );
      } else if (prev != null &&
          (prev.quality == NetworkQuality.offline ||
              prev.quality == NetworkQuality.slow)) {
        AppToast.show(
          'Back online',
          context: context,
          type: ToastType.success,
        );
      }
    });

    return const SizedBox.shrink();
  }
}
