import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

/// Hata türleri (gerekirse genişletebilirsin)
enum CloudErrorKind {
  permissionDenied,
  unauthenticated,
  network,
  unavailable, // service unavailable / deadline exceeded
  notFound,
  quota,
  unknown,
}

/// Firebase/Firestore hatalarını türe map’le
CloudErrorKind mapExceptionToKind(Object e) {
  final s = e.toString().toLowerCase();

  if (s.contains('permission-denied')) return CloudErrorKind.permissionDenied;
  if (s.contains('unauthenticated')) return CloudErrorKind.unauthenticated;
  if (s.contains('network') || s.contains('socketexception')) {
    return CloudErrorKind.network;
  }
  if (s.contains('unavailable') || s.contains('deadline-exceeded')) {
    return CloudErrorKind.unavailable;
  }
  if (s.contains('not-found')) return CloudErrorKind.notFound;
  if (s.contains('resource-exhausted') ||
      s.contains('quota') ||
      s.contains('429')) {
    return CloudErrorKind.quota;
  }
  return CloudErrorKind.unknown;
}

/// SnackBar / Dialog gösterimi için ortak yardımcı
class CloudErrorHandler {
  /// Hata nesnesinden anlamlı mesaj göster
  static void showFromException(Object e, {bool asDialog = false}) {
    final kind = mapExceptionToKind(e);
    show(kind, asDialog: asDialog);
  }

  /// Belirli bir hata türünü kullanıcı dostu mesajla göster
  static void show(CloudErrorKind kind, {bool asDialog = false}) {
    final ctx = navigatorKey.currentContext;
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
          color: Colors.orangeAccent,
        );
      case CloudErrorKind.unauthenticated:
        return _Msg(
          title: t.errSigninTitle,
          body: t.errSigninBody,
          color: Colors.orangeAccent,
        );
      case CloudErrorKind.network:
        return _Msg(
          title: t.errNetworkTitle,
          body: t.errNetworkBody,
          color: Colors.redAccent,
        );
      case CloudErrorKind.unavailable:
        return _Msg(
          title: t.errBusyTitle,
          body: t.errBusyBody,
          color: Colors.redAccent,
        );
      case CloudErrorKind.notFound:
        return _Msg(
          title: t.errNotFoundTitle,
          body: t.errNotFoundBody,
          color: Colors.redAccent,
        );
      case CloudErrorKind.quota:
        return _Msg(
          title: t.errQuotaTitle,
          body: t.errQuotaBody,
          color: Colors.redAccent,
        );
      case CloudErrorKind.unknown:
      default:
        return _Msg(
          title: t.errUnknownTitle,
          body: t.errUnknownBody,
          color: Colors.redAccent,
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
