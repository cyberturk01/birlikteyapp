// lib/widgets/role_gate.dart
import 'package:birlikteyapp/utils/context_perms.dart';
import 'package:flutter/material.dart';

import '../permissions/permissions.dart';

class RoleGate extends StatelessWidget {
  final FamilyPermission require;
  final Widget child;
  final Widget? fallback; // örn: SizedBox.shrink()

  const RoleGate({
    super.key,
    required this.require,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return context.can(require) ? child : (fallback ?? const SizedBox.shrink());
  }
}

class RoleDisabled extends StatelessWidget {
  final FamilyPermission require;
  final Widget Function(BuildContext, bool enabled) builder;

  const RoleDisabled({super.key, required this.require, required this.builder});

  @override
  Widget build(BuildContext context) {
    final ok = context.can(require);
    return AbsorbPointer(
      absorbing: !ok,
      child: Opacity(opacity: ok ? 1 : 0.5, child: builder(context, ok)),
    );
  }
}
