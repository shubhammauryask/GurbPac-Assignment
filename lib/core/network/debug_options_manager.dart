import '../errors/failures.dart';

class DebugOptionsManager {
  int simulatedDelayMs;
  bool force404Error;
  bool forceTimeoutError;
  bool forceValidationError;
  bool isOffline;

  DebugOptionsManager({
    this.simulatedDelayMs = 400,
    this.force404Error = false,
    this.forceTimeoutError = false,
    this.forceValidationError = false,
    this.isOffline = false,
  });

  Future<void> simulateNetworkLatency() async {
    if (simulatedDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: simulatedDelayMs));
    }
  }

  void checkAndThrowSimulatedErrors() {
    if (isOffline) {
      throw const NetworkException(
        'Device is currently offline. Displaying cached data.',
        code: 'SIMULATED_OFFLINE',
      );
    }
    if (forceTimeoutError) {
      throw const NetworkException(
        'Simulated network timeout (504). Please try again.',
        code: 'SIMULATED_TIMEOUT',
      );
    }
    if (force404Error) {
      throw const NotFoundException(
        'Simulated 404: The requested resource was not found.',
        code: 'SIMULATED_404',
      );
    }
    if (forceValidationError) {
      throw const ValidationException(
        'Simulated 400: Business validation failed on backend.',
        code: 'SIMULATED_VALIDATION_ERROR',
      );
    }
  }
}
