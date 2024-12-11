import 'dart:convert';

class MoneyOperation {
  final String type;
  String category;
  final DateTime date;
  double moneyAmount;

  MoneyOperation({
    required this.type,
    required this.category,
    required this.date,
    required this.moneyAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'moneyAmount': moneyAmount,
    };
  }

  factory MoneyOperation.fromJson(Map<String, dynamic> json) {
    return MoneyOperation(
      type: json['type'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      moneyAmount: json['moneyAmount'],
    );
  }

  String toJsonString() => jsonEncode(this.toJson());

  static MoneyOperation fromJsonString(String jsonString) {
    return MoneyOperation.fromJson(jsonDecode(jsonString));
  }
}
