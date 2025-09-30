import 'dart:async';
import 'dart:math';

typedef AsyncFn<T> = Future<T> Function();

class Retry {
  static Future<T> attempt<T>(
    AsyncFn<T> fn, {
    int maxAttempts = 5,
    int baseDelayMs = 300,
    bool Function(Object error)? retryOn,
  }) async {
    final rng = Random();
    var attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        final should = retryOn?.call(e) ?? true;
        if (!should || attempt >= maxAttempts) rethrow;
        final jitter = 0.5 + rng.nextDouble(); // 0.5..1.5
        final ms = (baseDelayMs * pow(2, attempt - 1) * jitter)
            .clamp(200, 8000)
            .toInt();
        await Future.delayed(Duration(milliseconds: ms));
      }
    }
  }
}
