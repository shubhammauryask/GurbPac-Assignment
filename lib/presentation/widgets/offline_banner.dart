import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/core_providers.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugOpts = ref.watch(debugOptionsProvider);

    final hasSimulatedError =
        debugOpts.force404Error ||
        debugOpts.forceTimeoutError ||
        debugOpts.forceValidationError;

    if (!debugOpts.isOffline && !hasSimulatedError) {
      return const SizedBox.shrink();
    }

    String text = 'Offline Mode Active — Showing Cached Data';
    Color bannerColor = AppColors.warning;

    if (hasSimulatedError) {
      text =
          'Debug Error Simulation Active (${_getSimulatedErrorName(debugOpts)})';
      bannerColor = AppColors.error;
    }

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            Icon(
              debugOpts.isOffline
                  ? Icons.wifi_off_rounded
                  : Icons.bug_report_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (debugOpts.isOffline) {
                  debugOpts.toggleOffline(false);
                } else {
                  debugOpts.toggleForce404(false);
                  debugOpts.toggleForceTimeout(false);
                  debugOpts.toggleForceValidation(false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RESET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSimulatedErrorName(DebugOptionsManagerNotifier opts) {
    if (opts.force404Error) return '404 Not Found';
    if (opts.forceTimeoutError) return '504 Timeout';
    if (opts.forceValidationError) return 'Validation Error';
    return 'Error';
  }
}
