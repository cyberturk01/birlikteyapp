// lib/utils/assignee.dart
class Assignee {
  static bool match(String? a, String? b) {
    final s1 = (a ?? '').trim();
    final s2 = (b ?? '').trim();
    if (s1.isEmpty || s2.isEmpty) return false;
    if (s1 == s2) return true;

    final re = RegExp(r'^You \((.+)\)$');
    String core(String s) {
      final m = re.firstMatch(s);
      return m != null ? m.group(1)! : s;
    }

    return core(s1) == core(s2);
  }
}
