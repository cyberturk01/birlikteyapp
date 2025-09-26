import 'package:shared_preferences/shared_preferences.dart';

class LastCategoryStore {
  static String _key(String uid) => 'lastCat:$uid';

  static Future<void> saveFor(String uid, String category) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(uid), category);
  }

  static Future<String?> readFor(String uid) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key(uid));
  }
}
