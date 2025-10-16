// lib/services/retry.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

typedef AsyncFn<T> = Future<T> Function();

class Retry {
  static Future<T> attempt<T>(
    AsyncFn<T> fn, {
    int maxAttempts = 5,
    Duration baseDelay = const Duration(milliseconds: 400),
    bool Function(Object error)? retryOn, // null ise hep dener
  }) async {
    final rng = Random();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('[Retry] attempt $attempt');
        return await fn();
      } catch (e) {
        final should = retryOn?.call(e) ?? true;
        final last = attempt >= maxAttempts;
        if (!should || last) rethrow;

        // exponential (1,2,4,8,...) * baseDelay + jitter (0.5..1.5)
        final factor = 1 << (attempt - 1);
        final jitter = 0.5 + rng.nextDouble(); // 0.5..1.5
        var ms = (baseDelay.inMilliseconds * factor * jitter).toInt();
        ms = ms.clamp(200, 8000);
        final delay = Duration(milliseconds: ms);

        debugPrint(
          '[Retry] failed (#$attempt): $e → wait ${delay.inMilliseconds}ms',
        );
        await Future.delayed(delay);
      }
    }
    // buraya normalde gelmez
    throw StateError('Retry fell through unexpectedly');
  }
}
