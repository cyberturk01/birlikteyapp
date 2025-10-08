import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

/// Hata türleri
enum CloudErrorKind {
  permissionDenied,
  unauthenticated,
  unavailable, // service unavailable / deadline exceeded
  network,
  timeout, // explicit timeout ayrımı
  notFound,
  alreadyExists,
  quota, // resource-exhausted / 429
  invalidArgument,
  failedPrecondition,
  aborted,
  cancelled,
  internal,
  dataLoss,
  outOfRange,
  unimplemented,
  unknown,
}

/// Firebase/Firestore hatalarını türe map’le
CloudErrorKind mapExceptionToKind(Object e) {
  // 1) FirebaseException.code varsa onu kullan
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return CloudErrorKind.permissionDenied;
      case 'unauthenticated':
        return CloudErrorKind.unauthenticated;
      case 'unavailable':
        return CloudErrorKind.unavailable;
      case 'deadline-exceeded':
        return CloudErrorKind.timeout;
      case 'not-found':
        return CloudErrorKind.notFound;
      case 'already-exists':
        return CloudErrorKind.alreadyExists;
      case 'resource-exhausted':
        return CloudErrorKind.quota;
      case 'invalid-argument':
        return CloudErrorKind.invalidArgument;
      case 'failed-precondition':
        return CloudErrorKind.failedPrecondition;
      case 'aborted':
        return CloudErrorKind.aborted;
      case 'cancelled':
        return CloudErrorKind.cancelled;
      case 'internal':
        return CloudErrorKind.internal;
      case 'data-loss':
        return CloudErrorKind.dataLoss;
      case 'out-of-range':
        return CloudErrorKind.outOfRange;
      case 'unimplemented':
        return CloudErrorKind.unimplemented;
      default:
        return CloudErrorKind.unknown;
    }
  }

  // 2) Aksi halde string-fallback (mevcut mantığının genişletilmişi)
  final s = e.toString().toLowerCase();
  if (s.contains('permission-denied')) return CloudErrorKind.permissionDenied;
  if (s.contains('unauthenticated')) return CloudErrorKind.unauthenticated;
  if (s.contains('deadline-exceeded') || s.contains('timeout')) {
    return CloudErrorKind.timeout;
  }
  if (s.contains('unavailable')) return CloudErrorKind.unavailable;
  if (s.contains('network') || s.contains('socketexception'))
    return CloudErrorKind.network;
  if (s.contains('not-found')) return CloudErrorKind.notFound;
  if (s.contains('already-exists')) return CloudErrorKind.alreadyExists;
  if (s.contains('resource-exhausted') ||
      s.contains('quota') ||
      s.contains('429'))
    return CloudErrorKind.quota;
  if (s.contains('invalid-argument')) return CloudErrorKind.invalidArgument;
  if (s.contains('failed-precondition'))
    return CloudErrorKind.failedPrecondition;
  if (s.contains('aborted')) return CloudErrorKind.aborted;
  if (s.contains('cancelled') || s.contains('canceled'))
    return CloudErrorKind.cancelled;
  if (s.contains('internal')) return CloudErrorKind.internal;
  if (s.contains('data-loss')) return CloudErrorKind.dataLoss;
  if (s.contains('out-of-range')) return CloudErrorKind.outOfRange;
  if (s.contains('unimplemented')) return CloudErrorKind.unimplemented;

  return CloudErrorKind.unknown;
}

class CloudErrorHandler {
  /// Hata nesnesinden anlamlı mesaj göster
  static void showFromException(
    Object e, {
    bool asDialog = false,
    BuildContext? context,
  }) {
    final kind = mapExceptionToKind(e);
    show(kind, asDialog: asDialog, context: context);
  }

  /// Belirli hata türünü kullanıcı dostu mesajla göster
  static void show(
    CloudErrorKind kind, {
    bool asDialog = false,
    BuildContext? context,
  }) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final t = AppLocalizations.of(ctx)!;
    final _Msg m = _messagesFor(kind, t);

    if (asDialog) {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text(m.title),
          content: Text(m.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(m.body),
          backgroundColor: m.color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Yerelleştirilmiş başlık/metin ve uygun renk
  static _Msg _messagesFor(CloudErrorKind kind, AppLocalizations t) {
    switch (kind) {
      case CloudErrorKind.permissionDenied:
        return _Msg(
          title: t.errPermissionTitle,
          body: t.errPermissionBody,
          color: Colors.amber.shade200,
        );
      case CloudErrorKind.unauthenticated:
        return _Msg(
          title: t.errSigninTitle,
          body: t.errSigninBody,
          color: Colors.amber.shade200,
        );
      case CloudErrorKind.unavailable:
        return _Msg(
          title: t.errBusyTitle,
          body: t.errBusyBody,
          color: Colors.orange.shade200,
        );
      case CloudErrorKind.timeout:
        return _Msg(
          title: t.errTimeoutTitle,
          body: t.errTimeoutBody,
          color: Colors.orange.shade200,
        );
      case CloudErrorKind.network:
        return _Msg(
          title: t.errNetworkTitle,
          body: t.errNetworkBody,
          color: Colors.red.shade200,
        );
      case CloudErrorKind.notFound:
        return _Msg(
          title: t.errNotFoundTitle,
          body: t.errNotFoundBody,
          color: Colors.red.shade200,
        );
      case CloudErrorKind.alreadyExists:
        return _Msg(
          title: t.errAlreadyExistsTitle,
          body: t.errAlreadyExistsBody,
          color: Colors.blueGrey.shade200,
        );
      case CloudErrorKind.quota:
        return _Msg(
          title: t.errQuotaTitle,
          body: t.errQuotaBody,
          color: Colors.red.shade200,
        );
      case CloudErrorKind.invalidArgument:
        return _Msg(
          title: t.errInvalidTitle,
          body: t.errInvalidBody,
          color: Colors.orange.shade200,
        );
      case CloudErrorKind.failedPrecondition:
        return _Msg(
          title: t.errPrecondTitle,
          body: t.errPrecondBody,
          color: Colors.orange.shade200,
        );
      case CloudErrorKind.aborted:
        return _Msg(
          title: t.errAbortedTitle,
          body: t.errAbortedBody,
          color: Colors.blueGrey.shade200,
        );
      case CloudErrorKind.cancelled:
        return _Msg(
          title: t.errCancelledTitle,
          body: t.errCancelledBody,
          color: Colors.blueGrey.shade200,
        );
      case CloudErrorKind.internal:
        return _Msg(
          title: t.errInternalTitle,
          body: t.errInternalBody,
          color: Colors.red.shade300,
        );
      case CloudErrorKind.dataLoss:
        return _Msg(
          title: t.errDataLossTitle,
          body: t.errDataLossBody,
          color: Colors.red.shade300,
        );
      case CloudErrorKind.outOfRange:
        return _Msg(
          title: t.errOutOfRangeTitle,
          body: t.errOutOfRangeBody,
          color: Colors.orange.shade200,
        );
      case CloudErrorKind.unimplemented:
        return _Msg(
          title: t.errUnimplementedTitle,
          body: t.errUnimplementedBody,
          color: Colors.blueGrey.shade200,
        );
      case CloudErrorKind.unknown:
      default:
        return _Msg(
          title: t.errUnknownTitle,
          body: t.errUnknownBody,
          color: Colors.red.shade200,
        );
    }
  }
}

class _Msg {
  final String title;
  final String body;
  final Color color;
  _Msg({required this.title, required this.body, required this.color});
}
