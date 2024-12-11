import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_journal/models/MoneyOperation.dart';

class EditCategoriesScene extends StatefulWidget {
  const EditCategoriesScene({super.key});

  @override
  State<EditCategoriesScene> createState() => _EditCategoriesSceneState();
}

class _EditCategoriesSceneState extends State<EditCategoriesScene> {
  List<String> costs = ['Траты'];
  List<String> incomes = ['Доходы'];
  List<MoneyOperation> operations = [];
  TextEditingController _newCategory = TextEditingController();

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

  Future<void> getCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      costs = prefs.getStringList('costs') ?? ['Траты'];
      incomes = prefs.getStringList('incomes') ?? ['Доходы'];
    });
  }

  Future<void> setCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('costs', costs);
    await prefs.setStringList('incomes', incomes);
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    loadOperations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Редактировать категории',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              setCategories().then((_) {
                Navigator.pop(context, {
                  'incomes': incomes,
                  'costs': costs,
                  'operations': operations,
                });
              });
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Доходы (${incomes.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            fontSize: 24),
                      ),
                      IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Отмена')),
                                  TextButton(
                                      onPressed: () {
                                        if (_newCategory.text
                                            .trim()
                                            .isNotEmpty) {
                                          setState(() {
                                            incomes
                                                .add(_newCategory.text.trim());
                                            setCategories();
                                          });
                                          _newCategory.clear();
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Text('Сохранить'))
                                ],
                                title: Text('Добавить доходы'),
                                content: TextField(
                                  controller: _newCategory,
                                  decoration: InputDecoration(
                                      hintText: 'Название категории...'),
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.add,
                            color: Colors.deepPurple,
                            size: 30,
                          ))
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: incomes.length,
                      itemBuilder: (context, index) {
                        var income = incomes[index];
                        return ListTile(
                          title: Text(
                            income,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (income == 'Зарплата') ...[
                                SizedBox.shrink()
                              ] else ...[
                                IconButton(
                                  onPressed: () {
                                    _newCategory.text = income;
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
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_newCategory.text
                                                  .trim()
                                                  .isNotEmpty) {
                                                operations.forEach((operation) {
                                                  if (operation.category ==
                                                      incomes[index]) {
                                                    operation.category =
                                                        _newCategory.text
                                                            .trim();
                                                  }
                                                });
                                                setState(() {
                                                  incomes[index] =
                                                      _newCategory.text.trim();
                                                });
                                                setCategories();
                                                saveOperations();
                                                _newCategory.clear();
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: Text('Сохранить'),
                                          ),
                                        ],
                                        title: Text(income),
                                        content: TextField(
                                          controller: _newCategory,
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
                                      incomes.removeAt(index);
                                    });
                                    setCategories();
                                  },
                                  icon: Icon(
                                    Icons.remove,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Траты (${costs.length})',
                        style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
                      IconButton(
                          onPressed: () {
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
                                        style: TextStyle(color: Colors.pink),
                                      )),
                                  TextButton(
                                      onPressed: () {
                                        if (_newCategory.text
                                            .trim()
                                            .isNotEmpty) {
                                          setState(() {
                                            costs.add(_newCategory.text.trim());
                                            setCategories();
                                          });
                                          _newCategory.clear();
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Text('Сохранить'))
                                ],
                                title: Text('Добавить траты'),
                                content: TextField(
                                  controller: _newCategory,
                                  decoration: InputDecoration(
                                      hintText: 'Название категории...'),
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.add,
                            color: Colors.deepPurple,
                            size: 30,
                          ))
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: costs.length,
                      itemBuilder: (context, index) {
                        var cost = costs[index];
                        return ListTile(
                          title: Text(
                            cost,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          subtitle:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            if (cost != 'Еда') ...[
                              IconButton(
                                onPressed: () {
                                  _newCategory.text = cost;
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
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (_newCategory.text
                                                .trim()
                                                .isNotEmpty) {
                                              setState(() {
                                                costs[index] =
                                                    _newCategory.text.trim();
                                              });
                                              setCategories();
                                              _newCategory.clear();
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          child: Text('Сохранить'),
                                        ),
                                      ],
                                      title: Text(cost),
                                      content: TextField(
                                        controller: _newCategory,
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
                                    costs.removeAt(index);
                                  });
                                  setCategories();
                                },
                                icon: Icon(
                                  Icons.remove,
                                  color: Colors.pink,
                                ),
                              ),
                            ],
                          ]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
