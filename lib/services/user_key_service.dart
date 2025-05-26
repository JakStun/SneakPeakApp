import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanoid/nanoid.dart';

class UserKeyChecker {
  static const String _storageKey = 'unique_user_key';

  static Future<String> getCreateUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? userKey = prefs.getString(_storageKey);

    if (userKey == null) {
      userKey = nanoid(); // Default is 21 characters, change to 10 if needed
      await prefs.setString(_storageKey, userKey);
    }

    return userKey;
  }
}