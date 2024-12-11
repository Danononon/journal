import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_journal/models/MoneyOperation.dart';

class MoneyOperationsStorage {
  static const String _key = 'moneyOperations';

  static Future<void> saveMoneyOperations(
      List<MoneyOperation> operations) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStrings =
        operations.map((operation) => operation.toJsonString()).toList();
    await prefs.setStringList(_key, jsonStrings);
  }

  static Future<List<MoneyOperation>> loadMoneyOperations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStrings = prefs.getStringList(_key);
    if (jsonStrings == null) return [];
    return jsonStrings
        .map((jsonString) => MoneyOperation.fromJsonString(jsonString))
        .toList();
  }
}
