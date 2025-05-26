import 'user_key_service.dart';

class LocalSettingsService {
  static late String userKey;

  static Future<void> initialize() async {
    userKey = await UserKeyChecker.getCreateUserKey();
  }
}