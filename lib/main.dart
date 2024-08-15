import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_excel/excel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Person> people = [];
  RangeValues filterHours = const RangeValues(0, 24);
  bool isVehicle = false;
  bool isPerson = false;
  bool onlyAnomalies = false;
  bool sortByHours = false;
  String path = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Flex(
        direction: Axis.horizontal,
        children: [
          Expanded(
            flex: 4,
            child: Flex(
              direction: Axis.vertical,
              children: [
                const Expanded(flex: 1, child: Text("test")),
                Expanded(
                  flex: 18,
                  child: ListView(
                    children: people.map((person) {
                      return PersonExpansionTile(person, filterHours);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue,
              child: ListView(
                children: [
                  // File input button
                  const SizedBox(
                    height: 10,
                  ),
                  TextButton(
                    onPressed: () {
                      FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowMultiple: false,
                        lockParentWindow: true,
                        allowedExtensions: ['xlsx'],
                      ).then((result) {
                        if (result != null) {
                          List<PlatformFile> files = result.files;
                          path = files[0].path!;
                          loadExcel(files[0].path!);
                        } else {
                          // User canceled the picker
                        }
                      });
                    },
                    child: const Text("Apri Excel"),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 15.0),
                    child: Text("Filtro ore "),
                  ),
                  Flex(direction: Axis.horizontal, children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                          "Inizio: ${filterHours.start} - Fine: ${filterHours.end}"),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          DropdownButton<double>(
                            value: filterHours.start,
                            onChanged: (double? newValue) {
                              setState(() {
                                filterHours =
                                    RangeValues(newValue!, filterHours.end);
                                loadExcel(path);
                              });
                            },
                            items: List<int>.generate(25, (index) => index)
                                .map<DropdownMenuItem<double>>((value) {
                              return DropdownMenuItem<double>(
                                value: value.toDouble(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                          const Text("-"),
                          DropdownButton<double>(
                            value: filterHours.end,
                            onChanged: (double? newValue) {
                              setState(() {
                                filterHours =
                                    RangeValues(filterHours.start, newValue!);
                                loadExcel(path);
                              });
                            },
                            items: List<int>.generate(25, (index) => index)
                                .map<DropdownMenuItem<double>>((value) {
                              return DropdownMenuItem<double>(
                                value: value.toDouble(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    )
                  ]),
                  CheckboxListTile(
                    value: isVehicle,
                    title: const Text("Veicoli"),
                    onChanged: (bool? value) {
                      setState(() {
                        isVehicle = value!;
                        loadExcel(path);
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: isPerson,
                    title: const Text("Persone"),
                    onChanged: (bool? value) {
                      setState(() {
                        isPerson = value!;
                        loadExcel(path);
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: onlyAnomalies,
                    title: const Text("Mostra solo anomalie"),
                    onChanged: (bool? value) {
                      setState(() {
                        onlyAnomalies = value!;
                        loadExcel(path);
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: sortByHours,
                    title: const Text("Ordina per ore"),
                    onChanged: (bool? value) {
                      setState(() {
                        sortByHours = value!;
                        loadExcel(path);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void loadExcel(String path) {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Person> extractedPeople = extractPeople(excel, 'Sheet', isVehicle,
        isPerson, filterHours, onlyAnomalies, sortByHours);

    setState(() {
      people = extractedPeople;
    });
  }
}

class Person {
  String codiceProgetto;
  String codiceCategoria;
  String descrizioneCategoria;
  String codiceID;
  String descrizioneDA;
  String codiceWBS;
  String descrizioneWBS;
  List<Day> days = [];

  Person(this.codiceProgetto, this.codiceCategoria, this.descrizioneCategoria,
      this.codiceID, this.descrizioneDA, this.codiceWBS, this.descrizioneWBS);

  void addDay(Day day) {
    days.add(day);
  }

  int countAnomalies(int min, int max) {
    print("$min - $max");
    int total = 0;
    for (Day day in days) {
      total += day.countAnomalies(min, max);
    }
    return total;
  }

  void sortDays() {
    //sort the list of days by total hours
    days.sort((a, b) => b.totalHours.compareTo(a.totalHours));
  }

  void sortHours() {
    //sort the list of hours by total hours
    for (Day day in days) {
      day.sortHours();
    }
  }

  double get totalHours {
    double total = 0;
    for (Day day in days) {
      total += day.totalHours;
    }
    return total;
  }

  double get ordinarie {
    double total = 0;
    for (Day day in days) {
      total += day.ordinario;
    }
    return total;
  }

  double get pioggia {
    double total = 0;
    for (Day day in days) {
      total += day.pioggia;
    }
    return total;
  }

  double get malattia {
    double total = 0;
    for (Day day in days) {
      total += day.malattia;
    }
    return total;
  }

  double get ferie {
    double total = 0;
    for (Day day in days) {
      total += day.ferie;
    }
    return total;
  }

  List<Day> getAnomalies(int min, int max) {
    List<Day> anomalies = [];
    for (Day day in days) {
      if (day.countAnomalies(min, max) > 0) {
        anomalies.add(day);
      }
    }
    return anomalies;
  }
}

class Day {
  int day;
  List<Hour> hours = [];

  Day(this.day);
  void addHour(Hour hour) {
    hours.add(hour);
  }

  double get totalHours {
    double total = 0;
    for (Hour hour in hours) {
      total += double.parse(hour.ordinario ?? '0') +
          double.parse(hour.pioggia ?? '0') +
          double.parse(hour.malattia ?? '0') +
          double.parse(hour.ferie ?? '0');
    }
    return total;
  }

  void sortHours() {
    //sort the list of hours by total hours
    hours.sort((a, b) => b.totalHours.compareTo(a.totalHours));
  }

  int get ordinario {
    int total = 0;
    for (Hour hour in hours) {
      total += int.parse(hour.ordinario ?? '0');
    }
    return total;
  }

  int get pioggia {
    int total = 0;
    for (Hour hour in hours) {
      total += int.parse(hour.pioggia ?? '0');
    }
    return total;
  }

  int get malattia {
    int total = 0;
    for (Hour hour in hours) {
      total += int.parse(hour.malattia ?? '0');
    }
    return total;
  }

  int get ferie {
    int total = 0;
    for (Hour hour in hours) {
      total += int.parse(hour.ferie ?? '0');
    }
    return total;
  }

  int countAnomalies(int min, int max) {
    int total = 0;
    for (Hour hour in hours) {
      if (hour.totalHours < min || hour.totalHours > max) {
        total++;
      }
    }
    return total;
  }

  List<Hour> get anomalies {
    List<Hour> anomalies = [];
    for (Hour hour in hours) {
      if (hour.totalHours < 8 || hour.totalHours > 24) {
        anomalies.add(hour);
      }
    }
    return anomalies;
  }
}

class Hour {
  String? note;
  String? ordinario;
  String? pioggia;
  String? malattia;
  String? ferie;
  String progetto;
  String progettoID;

  List<Day> days = [];

  Hour(
      {this.note,
      this.ordinario,
      this.pioggia,
      this.malattia,
      this.ferie,
      required this.progetto,
      required this.progettoID});

  double get totalHours {
    double total = 0;
    total += double.parse(ordinario ?? '0') +
        double.parse(pioggia ?? '0') +
        double.parse(malattia ?? '0') +
        double.parse(ferie ?? '0');
    return total;
  }
}

List<Person> extractPeople(
    Excel excel,
    String sheetName,
    bool isVehicle,
    bool isPerson,
    RangeValues filterHours,
    bool onlyAnomalies,
    bool sortByHours) {
  List<Person> people = [];
  var sheet = excel.tables[sheetName];

  if (sheet == null) return people;

  for (var row in sheet.rows) {
    Person? person;
    bool addEnabler = false;

    // Check if the person already exists in the list
    // Track day number

    for (var personE in people) {
      if (personE.codiceID == row[3]?.value) {
        person = personE;
        break;
      }
    }

    if (row[0]?.value == null ||
        row[3]?.value == null ||
        row[0]?.value.toLowerCase().contains('cod') ||
        row[3]?.value.toLowerCase().contains('cod')) {
      continue;
    }

    if (!isVehicle && int.parse(row[3]?.value ?? '0') >= 20000) {
      // Skip vehicles
      continue;
    }
    if (!isPerson && int.parse(row[3]?.value ?? '0') < 20000) {
      // Skip people
      continue;
    }

    // If the person doesn't exist, create a new one
    if (person == null) {
      person = Person(
        row[0]?.value ?? '', // Cod. Progetto
        row[1]?.value ?? '', // Cod. Categoria
        row[2]?.value ?? '', // Des. Categoria
        row[3]?.value ?? '', // Cod. D/A Az.
        row[4]?.value ?? '', // Des. D/A Az.
        row[5]?.value ?? '', // Cod. WBS
        row[6]?.value ?? '', // Des. WBS
      );
      addEnabler = true;
    }

    // Iterate over the repeating day-related columns
    int indx = 7; // Index starts after the fixed columns
    int date = 1;

    while (indx < row.length) {
      Day day = Day(date);
      if (person.days.isEmpty) {
        person.addDay(day);
      }

      try {
        Hour hour = Hour(
          note: row[indx]?.value?.toString(),
          ordinario: row[indx + 1]?.value?.toString(),
          pioggia: row[indx + 2]?.value?.toString(),
          malattia: row[indx + 3]?.value?.toString(),
          ferie: row[indx + 4]?.value?.toString(),
          progetto: row[6]?.value?.toString() ?? '', // Des. WBS
          progettoID: row[0]?.value?.toString() ?? '', // Cod. Progetto
        );

        //if date exists in person.days
        if (person.days.any((d) => d.day == date)) {
          person.days
              .firstWhere((d) => d.day == date)
              .addHour(hour); // Add the hour to the day
        } else {
          person.days.add(day);
          person.days.firstWhere((d) => d.day == date).addHour(hour);
        }
      } catch (e) {
        // Handle exceptions quietly, as in the Python code
        print("Error processing day data: $e");
      }

      indx +=
          5; // Move to the next set of Note, Ordinario, Pioggia, Malattia, Ferie
      date += 1; // Increment the day
    }

    // Add the new person to the list
    if (addEnabler) {
      people.add(person);
    }
  }
  print("Extracted ${people.length} people");
  List<Person> filteredPeople = [];
  if (!onlyAnomalies) {
    filteredPeople = people;
  } else {
    for (Person person in people) {
      if (person.countAnomalies(
              filterHours.start.toInt(), filterHours.end.toInt()) >
          0) {
        filteredPeople.add(person);
      }
    }
  }

  if (sortByHours) {
    for (Person person in filteredPeople) {
      person.sortDays();
      person.sortHours();
    }
  }

  return filteredPeople;
}

class PersonExpansionTile extends StatelessWidget {
  final Person person;
  final RangeValues filterHours;
  const PersonExpansionTile(this.person, this.filterHours, {super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
          "${person.descrizioneDA} anomalie: ${person.countAnomalies(filterHours.start.toInt(), filterHours.end.toInt())} "),
      subtitle: Text("ore mensili: ${person.totalHours}"),
      trailing: FittedBox(
        fit: BoxFit.contain,
        child: Row(children: [
          TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: person.codiceID));
              },
              child: const Text("Copia IDPersonale")),
          const Checkbox(value: false, onChanged: null),
        ]),
      ),
      children: person.days.map((day) {
        return DayExpansionTile(day, filterHours: filterHours);
      }).toList(),
    );
  }
}

class DayExpansionTile extends StatefulWidget {
  final Day day;
  final RangeValues filterHours;
  const DayExpansionTile(this.day, {required this.filterHours, super.key});

  @override
  State<DayExpansionTile> createState() => _DayExpansionTileState();
}

class _DayExpansionTileState extends State<DayExpansionTile> {
  @override
  Widget build(
    BuildContext context,
  ) {
    return ExpansionTile(
      title: Text(
          "Giorno ${widget.day.day} Anomalie: ${widget.day.countAnomalies(widget.filterHours.start.toInt(), widget.filterHours.end.toInt())}"),
      subtitle: Text(
          "ordinario: ${widget.day.ordinario} pioggia: ${widget.day.pioggia} malattia: ${widget.day.malattia}, ferie: ${widget.day.ferie}, ore: ${widget.day.totalHours}"),
      children: widget.day.hours.map((hour) {
        return ListTile(
          title: HourExpansionTile(hour),
        );
      }).toList(),
    );
  }
}

class HourExpansionTile extends StatefulWidget {
  final Hour hour;
  const HourExpansionTile(this.hour, {super.key});
  @override
  State<HourExpansionTile> createState() => _HourExpansionTileState();
}

class _HourExpansionTileState extends State<HourExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
          "${widget.hour.progetto} - ${widget.hour.progettoID} - ore: ${widget.hour.totalHours}"),
      subtitle: Text(
          "ordinario: ${widget.hour.ordinario}, pioggia: ${widget.hour.pioggia}, malattia: ${widget.hour.malattia}, ferie: ${widget.hour.ferie}, totale: ${widget.hour.totalHours}"),
      trailing: TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.hour.progettoID));
          },
          child: Text("Copia IDCantiere")),
    );
  }
}

// class AnomalyTypeExpansionTile extends StatelessWidget {
//   final Day day;
//   const AnomalyTypeExpansionTile(this.day, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ExpansionTile(
//       title: Text("Giorno "),
//       subtitle: Text(
//           "Note: ${day.note ?? 'N/A'}, Ordinario: ${day.ordinario ?? 'N/A'}, Totale: ${day.ordinario ?? '0'} ore"),
//       tilePadding: EdgeInsets.only(left: 20),
//       children: [
//         ListTile(
//           title: Text("${day.ordinario ?? '0'} ore"),
//           subtitle: Text("presso: ${day.progetto}"),
//           contentPadding: EdgeInsets.only(left: 40),
//           trailing: TextButton(
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: day.progettoID));
//               },
//               child: Text("Copia IDCantiere")),
//         ),
//       ],
//     );
//   }
// }
