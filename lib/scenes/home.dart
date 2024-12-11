import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:eco_journal/models/MoneyOperation.dart';
import 'package:eco_journal/scenes/report.dart';
import 'package:eco_journal/scenes/editCategories.dart';

class HomeScene extends StatefulWidget {
  const HomeScene({super.key});

  @override
  State<HomeScene> createState() => _HomeSceneState();
}

class _HomeSceneState extends State<HomeScene> {
  List<String> costs = ['Спорт'];
  List<String> incomes = ['Зарплата'];
  String? selectedItem = 'Траты';
  DateTime? selectedDate = DateTime.now();
  List<MoneyOperation> operations = [];
  double? totalCash = 0.0;

  TextEditingController _costs = TextEditingController();
  TextEditingController _incomes = TextEditingController();
  TextEditingController _amount = TextEditingController();
  TextEditingController _newMoneyAmount = TextEditingController();

  Future<void> getCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      costs = prefs.getStringList('costs') ?? ['Спорт'];
      incomes = prefs.getStringList('incomes') ?? ['Зарплата'];
    });
  }

  void setCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('costs', costs);
    prefs.setStringList('incomes', incomes);
  }

  Future<void> loadOperations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStrings = prefs.getStringList('moneyOperations');
    if (jsonStrings != null) {
      List<MoneyOperation> loadedOperations = jsonStrings
          .map((jsonString) => MoneyOperation.fromJsonString(jsonString))
          .toList();
      setState(() {
        operations = loadedOperations;
      });
    }
  }

  Future<void> saveOperations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStrings =
        operations.map((operation) => operation.toJsonString()).toList();
    prefs.setStringList('moneyOperations', jsonStrings);
  }

  Future<void> setTotalCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double totalCosts = 0;
    double totalIncomes = 0;

    operations.forEach((operation) {
      if (operation.type == 'Траты') {
        totalCosts += operation.moneyAmount;
      } else if (operation.type == 'Доходы') {
        totalIncomes += operation.moneyAmount;
      }
    });

    totalCash = totalIncomes - totalCosts;
    prefs.setDouble('totalCash', totalCash!);
  }

  Future<void> getTotalCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getDouble('totalCash') ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    loadOperations();
    getTotalCash();
    setTotalCash();
  }

  @override
  void dispose() {
    _costs.dispose();
    _incomes.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    String? selectedCategory = selectedItem == 'Траты' ? costs[0] : incomes[0];

    void _addOperation() async {
      if (_amount.text.contains('-')) {
        _amount.text = _amount.text.replaceAll('-', '');
      }

      double? newValue = double.tryParse(_amount.text);
      if (newValue == null) {
        print('Invalid value.');
        return;
      }

      _amount.clear();

      MoneyOperation newOperation = MoneyOperation(
        type: selectedItem!,
        category: selectedCategory!,
        date: selectedDate!,
        moneyAmount: newValue,
      );

      setState(() {
        operations.add(newOperation);
      });

      await saveOperations();
      Navigator.of(context).pop();
      selectedItem = 'Траты';
      selectedCategory = costs[0];
      selectedDate = DateTime.now();
    }

    List<MoneyOperation> todaysOperations = operations.where((operation) {
      DateTime now = DateTime.now();
      return operation.date.year == now.year &&
          operation.date.month == now.month &&
          operation.date.day == now.day;
    }).toList();

    todaysOperations = todaysOperations.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Главная',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.fact_check,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportScene()),
                    );

                    if (result != null) {
                      setState(() {
                        totalCash = result['totalCash'];
                        operations =
                            List<MoneyOperation>.from(result['operations']);
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditCategoriesScene()),
                    );

                    if (result != null) {
                      setState(() {
                        incomes = result['incomes'];
                        costs = result['costs'];
                        operations =
                        List<MoneyOperation>.from(result['operations']);
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Бумажник: ${NumberFormat('#,###.00').format(totalCash)} руб',
                style: TextStyle(
                    color: totalCash! > 0 ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                selectedItem = 'Траты';
                                selectedCategory = costs[0];
                                selectedDate = DateTime.now();
                                _amount.clear();
                              },
                              child: Text(
                                'Отмена',
                                style: TextStyle(color: Colors.pink),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _addOperation();
                                setTotalCash();
                              },
                              child: Text('Сохранить'),
                            ),
                          ],
                          title: Text('Новая запись'),
                          content: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: DropdownButton<String>(
                                  value: selectedItem,
                                  items: ['Траты', 'Доходы'].map((String item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedItem = newValue!;
                                      selectedCategory = selectedItem == 'Траты'
                                          ? costs[0]
                                          : incomes[0];
                                    });
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  items: (selectedItem == 'Доходы'
                                          ? incomes
                                          : costs)
                                      .map((String item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedCategory = newValue!;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                      'Выберите дату: ${selectedDate != null ? DateFormat('dd.MM.yyyy').format(selectedDate!) : ''}'),
                                  IconButton(
                                    onPressed: () async {
                                      DateTime? selectDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate!,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectDate != null) {
                                        setState(() {
                                          selectedDate = selectDate;
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      Icons.calendar_month,
                                      color: Colors.deepPurple,
                                    ),
                                  )
                                ],
                              ),
                              TextField(
                                controller: _amount,
                                decoration:
                                    InputDecoration(hintText: 'Сумма...'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: width * 0.9,
                  height: height * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Добавить запись',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (todaysOperations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Последние операции',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
              ),
              Expanded(
                  child: ListView.builder(
                      itemCount: todaysOperations.length,
                      itemBuilder: (context, index) {
                        final operation = todaysOperations[index];
                        return ListTile(
                          title: Text(
                            '${operation.category}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple),
                          ),
                          subtitle: Text(
                            DateFormat('dd.MM.yyyy').format(operation.date),
                            style: TextStyle(color: Colors.pink),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${operation.type == 'Траты' ? '-' : '+'}${NumberFormat('#,###.00').format(operation.moneyAmount)} руб',
                                style: TextStyle(
                                    color: operation.type == 'Траты'
                                        ? Colors.red
                                        : Colors.green),
                              ),
                              IconButton(
                                onPressed: () {
                                  _newMoneyAmount.text =
                                      operation.moneyAmount.toString();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Отмена',
                                              style:
                                                  TextStyle(color: Colors.pink),
                                            )),
                                        TextButton(
                                            onPressed: () {
                                              if (_newMoneyAmount.text
                                                  .contains('-')) {
                                                _newMoneyAmount.text =
                                                    _newMoneyAmount.text
                                                        .replaceAll('-', '');
                                              }

                                              if (_newMoneyAmount.text
                                                  .trim()
                                                  .isNotEmpty) {
                                                setState(() {
                                                  operation.moneyAmount =
                                                      double.parse(
                                                          _newMoneyAmount.text
                                                              .trim());
                                                  saveOperations();
                                                  setTotalCash();
                                                });
                                                _newMoneyAmount.clear();
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: Text('Сохранить'))
                                      ],
                                      title: Text('${operation.type}'),
                                      content: TextField(
                                        controller: _newMoneyAmount,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    operations.remove(operation);
                                    saveOperations();
                                    setTotalCash();
                                  });
                                },
                                icon: Icon(
                                  Icons.remove,
                                  color: Colors.pink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }))
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Сегодня никаких операций не проводилось',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    )),
              )
            ],
          ],
        ),
      ),
    );
  }
}
