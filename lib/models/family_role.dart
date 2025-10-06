enum FamilyRole { owner, editor, member, viewer }

FamilyRole roleFromString(String? s) {
  switch (s) {
    case 'owner':
      return FamilyRole.owner;
    case 'editor':
      return FamilyRole.editor;
    case 'viewer':
      return FamilyRole.viewer;
    case 'member':
      return FamilyRole.member;
    default:
      return FamilyRole.member;
  }
}

String? roleToString(FamilyRole? r) => r?.name;
