import 'dart:io';
import 'package:anomaly/people/people.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_excel/excel.dart';

class Personal extends StatefulWidget {
  const Personal({super.key});

  @override
  State<Personal> createState() => _PersonalState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Personal';
  }
}

class _PersonalState extends State<Personal> {
  late String? path;
  RangeValues filterHours = const RangeValues(0, 24);
  List<Person> people = [];
  bool isVehicle = false;
  bool isPerson = false;
  bool onlyAnomalies = false;
  bool sortByHours = false;

  @override
  void initState() {
    super.initState();
    path = "";
  }

  @override
  Widget build(BuildContext context) {
    DataTableSource personDataSource = PersonDataSource(people, filterHours);
    void loadExcel(String path) {
      if (kDebugMode) {
        print(path);
      }
      var bytes = File(path).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      List<Person> extractedPeople = extractPeople(excel, 'Sheet', isVehicle,
          isPerson, filterHours, onlyAnomalies, sortByHours);

      setState(() {
        people = extractedPeople;
      });
    }

    return Flex(
      direction: Axis.horizontal,
      children: [
        Expanded(
          flex: 4,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: PaginatedDataTable(
                        rowsPerPage:
                            MediaQuery.of(context).size.width > 800 ? 12 : 8,
                        source: personDataSource,
                        columnSpacing: 10,
                        header: const Text("Personale"),
                        sortColumnIndex: 1,
                        showEmptyRows: true,
                        columns: [
                          const DataColumn(
                              headingRowAlignment: MainAxisAlignment.center,
                              label: SizedBox(
                                width: 350,
                                child: Text("Nome"),
                              )),
                          const DataColumn(
                            headingRowAlignment: MainAxisAlignment.center,
                            label: Text("ID"),
                            numeric: true,
                          ),
                          ...[
                            for (var i = 1; i < 32; i++)
                              DataColumn(
                                  headingRowAlignment: MainAxisAlignment.end,
                                  label: SizedBox(
                                    width: 300,
                                    child: Flex(
                                        direction: Axis.horizontal,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text("$i",
                                                textAlign: TextAlign.start),
                                          ),
                                          const Expanded(
                                              flex: 2,
                                              child: Text(
                                                "Ord",
                                                textAlign: TextAlign.center,
                                              )),
                                          const Expanded(
                                            flex: 2,
                                            child: Text("Pio",
                                                textAlign: TextAlign.center),
                                          ),
                                          const Expanded(
                                              flex: 2,
                                              child: Text("Mal",
                                                  textAlign: TextAlign.center)),
                                          const Expanded(
                                              flex: 2,
                                              child: Text("Fer",
                                                  textAlign: TextAlign.center)),
                                        ]),
                                  ))
                          ]
                        ]),
                  )),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blue,
            child: ListView(
              children: [
                const SizedBox(height: 10),
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
                              loadExcel(path!);
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
                              loadExcel(path!);
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
                      loadExcel(path!);
                    });
                  },
                ),
                CheckboxListTile(
                  value: isPerson,
                  title: const Text("Persone"),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null) {
                        isPerson = value;
                        if (path != null && path!.isNotEmpty) {
                          if (kDebugMode) {
                            print(path);
                          }
                          loadExcel(path!);
                        } else {
                          if (kDebugMode) {
                            print("Error: Path is null or empty.");
                          }
                        }
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  value: onlyAnomalies,
                  title: const Text("Mostra solo anomalie"),
                  onChanged: (bool? value) {
                    setState(() {
                      onlyAnomalies = value!;
                      loadExcel(path!);
                    });
                  },
                ),
                CheckboxListTile(
                  value: sortByHours,
                  title: const Text("Ordina per ore"),
                  onChanged: (bool? value) {
                    setState(() {
                      sortByHours = value!;
                      loadExcel(path!);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
