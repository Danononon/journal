import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:eco_journal/models/MoneyOperation.dart';

class ReportScene extends StatefulWidget {
  const ReportScene({super.key});

  @override
  State<ReportScene> createState() => _ReportSceneState();
}

class _ReportSceneState extends State<ReportScene> {
  List<String> reportsPeriod = ['День', 'Неделя', 'Месяц'];
  String selectedReportPeriod = 'День';
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDate1;
  DateTime selectedDate2 = DateTime.now();
  List<String> costs = ['Спорт'];
  List<String> incomes = ['Зарплата'];
  String? selectedItem = 'Все';
  String? selectedCategory;
  List<MoneyOperation> operations = [];
  double? totalCash = 0.0;
  TextEditingController _newMoneyAmount = TextEditingController();

  Future<void> getCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      costs = prefs.getStringList('costs') ?? ['Спорт'];
      incomes = prefs.getStringList('incomes') ?? ['Зарплата'];
    });
  }

  Future<void> saveOperations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStrings =
        operations.map((operation) => operation.toJsonString()).toList();
    prefs.setStringList('moneyOperations', jsonStrings);
  }

  Future<void> setTotalCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double costs = 0;
    double incomes = 0;

    operations.forEach((operation) {
      if (operation.type == 'Траты') {
        costs += operation.moneyAmount;
      } else if (operation.type == 'Доходы') {
        incomes += operation.moneyAmount;
      }
    });

    totalCash = incomes - costs;
    prefs.setDouble('totalCash', totalCash!);
  }

  Future<void> getTotalCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getDouble('totalCash') ?? 0.0;
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

  @override
  void initState() {
    super.initState();
    getCategories();
    loadOperations();
    selectedCategory = selectedItem == 'Траты'
        ? costs[0]
        : selectedItem == 'Доходы'
            ? incomes[0]
            : 'none';
  }

  List<MoneyOperation> updateOperations(
      DateTime? start, DateTime? end, String? operationType, String? category) {
    return operations.where((operation) {
      bool isInDateRange = true;

      if (start != selectedDate) {
        isInDateRange =
            operation.date.isAfter(start!) && operation.date.isBefore(end!);
      } else {
        isInDateRange = operation.date.year == start?.year &&
            operation.date.month == start?.month &&
            operation.date.day == start?.day;
      }

      bool isCorrectType =
          operationType == 'Все' || operation.type == operationType;
      bool isCorrectCategory =
          category == 'none' || operation.category == category;

      return isInDateRange && isCorrectType && isCorrectCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    selectedDate1 = selectedReportPeriod == 'Неделя'
        ? selectedDate2.add(Duration(days: -7))
        : selectedDate2.add(Duration(days: -30));

    List<MoneyOperation> filteredOperations = updateOperations(
      selectedReportPeriod == 'День' ? selectedDate : selectedDate1,
      selectedReportPeriod == 'День' ? selectedDate : selectedDate2,
      selectedItem,
      selectedCategory,
    );

    filteredOperations = filteredOperations.reversed.toList();

    double totalCosts = 0;
    double totalIncomes = 0;

    filteredOperations.forEach((operation) {
      if (operation.type == 'Траты') {
        totalCosts += operation.moneyAmount;
      } else if (operation.type == 'Доходы') {
        totalIncomes += operation.moneyAmount;
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Отчет',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              setTotalCash().then((_) {
                Navigator.pop(context, {
                  'totalCash': totalCash,
                  'operations': operations,
                });
              });
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Отчет за',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedReportPeriod,
                  items: reportsPeriod.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReportPeriod = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          if (selectedReportPeriod == 'День') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    'Выберите дату ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
                    style: TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () async {
                      DateTime? selectDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
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
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    'Начало ${DateFormat('dd.MM.yyyy').format(selectedDate1!)}',
                  ),
                  IconButton(
                    onPressed: () async {
                      DateTime? selectDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate1!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectDate != null) {
                        setState(() {
                          selectedDate1 = selectDate;
                          selectedDate2 = selectedReportPeriod == 'Неделя'
                              ? selectedDate1!.add(Duration(days: 7))
                              : selectedDate1!.add(Duration(days: 30));
                        });
                      }
                    },
                    icon: Icon(
                      Icons.calendar_month,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Text(
                      'Окончание ${DateFormat('dd.MM.yyyy').format(selectedDate2)}'),
                  IconButton(
                    onPressed: () async {
                      DateTime? selectDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate2,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectDate != null) {
                        setState(() {
                          selectedDate2 = selectDate;
                          selectedDate1 = selectedReportPeriod == 'Неделя'
                              ? selectedDate2.add(Duration(days: -7))
                              : selectedDate2.add(Duration(days: -30));
                        });
                      }
                    },
                    icon: Icon(
                      Icons.calendar_month,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: DropdownButton<String>(
                    value: selectedItem,
                    items: ['Все', 'Траты', 'Доходы'].map((String item) {
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
                            : selectedItem == 'Доходы'
                                ? incomes[0]
                                : 'none';
                      });
                    },
                  ),
                ),
              ),
              if (selectedCategory != 'none') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      items: (selectedItem == 'Доходы' ? incomes : costs)
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
                ),
              ],
            ],
          ),
          if (filteredOperations.isNotEmpty) ...[
            Text(
              'Операции',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            if (selectedItem == 'Все') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Доходы: ',
                  ),
                  Text(
                    '${NumberFormat('#,###.00').format(totalIncomes)}',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  Text(' затраты: '),
                  Text(
                    '${NumberFormat('#,###.00').format(totalCosts)}',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${totalIncomes - totalCosts <= 0 ? '' : '+'}${totalIncomes - totalCosts} руб)',
                    style: TextStyle(
                        color: totalIncomes - totalCosts > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold),
                  )
                ],
              )
            ] else ...[
              Text(
                '${selectedItem!}: ${selectedItem == 'Доходы' ? NumberFormat('#,###.00').format(totalIncomes) : NumberFormat('#,###.00').format(totalCosts)} руб',
                style: TextStyle(
                    color:
                        selectedItem == 'Доходы' ? Colors.green : Colors.red),
              ),
            ],
            SizedBox(
              height: 16,
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: filteredOperations.length,
                    itemBuilder: (context, index) {
                      final operation = filteredOperations[index];
                      return ListTile(
                        title: Text(
                          '${operation.category}',
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
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
                                                    double.parse(_newMoneyAmount
                                                        .text
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
                                  setTotalCash();
                                  saveOperations();
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
            SizedBox(
              height: 16,
            ),
            Text(
              'Операций не найдено',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold),
            )
          ],
        ],
      ),
    );
  }
}
