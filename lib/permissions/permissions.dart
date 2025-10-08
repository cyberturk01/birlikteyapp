// lib/permissions/permissions.dart
import '../models/family_role.dart';

enum FamilyPermission {
  manageFamily, // aile ayarları, aileyi sil, davet kodunu yönet
  manageMembers, // üye ekle/çıkar, rol değiştir
  manageBudgets, // harcama bütçeleri, ayarlar
  writeTasks, // görev ekle/sil/düzenle/tamamlama
  writeItems, // market listesi ekle/sil/düzenle/tamamlama
  writeWeekly, // haftalık görevleri yönet
  writeExpenses, // harcama ekle/sil/düzenle
  viewLeaderboard, // skor tablosu
}

class RolePermissions {
  static final Map<FamilyRole, Set<FamilyPermission>> _byRole = {
    FamilyRole.owner: {
      FamilyPermission.manageFamily,
      FamilyPermission.manageMembers,
      FamilyPermission.manageBudgets,
      FamilyPermission.writeTasks,
      FamilyPermission.writeItems,
      FamilyPermission.writeWeekly,
      FamilyPermission.writeExpenses,
      FamilyPermission.viewLeaderboard,
    },
    FamilyRole.editor: {
      FamilyPermission.manageBudgets,
      FamilyPermission.writeTasks,
      FamilyPermission.writeItems,
      FamilyPermission.writeWeekly,
      FamilyPermission.writeExpenses,
      FamilyPermission.viewLeaderboard,
    },
    FamilyRole.member: {
      FamilyPermission.writeTasks,
      FamilyPermission.writeItems,
      FamilyPermission.writeWeekly,
      FamilyPermission.writeExpenses,
      FamilyPermission.viewLeaderboard,
    },
    FamilyRole.viewer: {
      FamilyPermission.viewLeaderboard,
      // yalnızca okuma; hiçbir write/manage yok
    },
  };

  static bool can(FamilyRole? role, FamilyPermission perm) {
    if (role == null) return false;
    return _byRole[role]?.contains(perm) ?? false;
  }
}
