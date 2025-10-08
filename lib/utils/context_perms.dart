import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/family_role.dart';
import '../permissions/permissions.dart';
import '../providers/family_provider.dart';

extension PermsX on BuildContext {
  FamilyRole? get myRole => read<FamilyProvider>().myRole;
  bool can(FamilyPermission p) => RolePermissions.can(myRole, p);

  bool get canManageFamily => can(FamilyPermission.manageFamily);
  bool get canManageMembers => can(FamilyPermission.manageMembers);
  bool get canManageBudgets => can(FamilyPermission.manageBudgets);
  bool get canWriteTasks => can(FamilyPermission.writeTasks);
  bool get canWriteItems => can(FamilyPermission.writeItems);
  bool get canWriteWeekly => can(FamilyPermission.writeWeekly);
  bool get canWriteExpenses => can(FamilyPermission.writeExpenses);
  bool get canSeeLeaderboard => can(FamilyPermission.viewLeaderboard);
}
