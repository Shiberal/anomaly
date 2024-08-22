// ignore_for_file: file_names

import 'dart:io';
import 'package:anomaly/people/hours.dart';
import 'package:anomaly/people/people.dart';
import 'package:anomaly/places.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_excel/excel.dart';

// ignore: must_be_immutable
class Personal extends StatefulWidget {
  Personal(this.placesManager, this.people, this.filterHours, this.isPerson,
      this.isVehicle, this.onlyAnomalies, this.sortByHours, this.path,
      {super.key});

  @override
  State<Personal> createState() => _PersonalState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Personal';
  }

  final PlacesManager placesManager;
  List<Person> people;
  RangeValues filterHours;
  bool isPerson;
  bool isVehicle;
  bool onlyAnomalies;
  bool sortByHours;
  String path;
}

class _PersonalState extends State<Personal> {
  late Person? selectedPerson;
  late int dayIndx;

  @override
  void initState() {
    selectedPerson = (widget.people.isNotEmpty ? widget.people[0] : null);
    dayIndx = 0;
    super.initState();
  }

  void updateSelectedPerson(Person person, int dayIndxCL) {
    setState(() {
      selectedPerson = person;
      dayIndx = dayIndxCL - 1;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    DataTableSource personDataSource = PersonDataSource(
        widget.people,
        widget.filterHours,
        selectedPerson,
        updateSelectedPerson,
        widget.placesManager);
    void loadExcel(String path) {
      if (kDebugMode) {
        print(path);
      }
      var bytes = File(path).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      List<Person> extractedPeople = extractPeople(
          excel,
          'Sheet',
          widget.isVehicle,
          widget.isPerson,
          widget.filterHours,
          widget.onlyAnomalies,
          widget.sortByHours,
          widget.placesManager);

      setState(() {
        widget.people = extractedPeople;
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
                  flex: 3,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: PaginatedDataTable(
                        rowsPerPage:
                            MediaQuery.of(context).size.width > 800 ? 9 : 8,
                        source: personDataSource,
                        columnSpacing: 10,
                        header: const Text("Personale"),
                        sortColumnIndex: 1,
                        dataRowMaxHeight: 50,
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
                        widget.path = files[0].path!;
                        loadExcel(widget.path);
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
                        "Inizio: ${widget.filterHours.start} - Fine: ${widget.filterHours.end}"),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DropdownButton<double>(
                          value: widget.filterHours.start,
                          onChanged: (double? newValue) {
                            setState(() {
                              widget.filterHours = RangeValues(
                                  newValue!, widget.filterHours.end);
                              loadExcel(widget.path);
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
                          value: widget.filterHours.end,
                          onChanged: (double? newValue) {
                            setState(() {
                              widget.filterHours = RangeValues(
                                  widget.filterHours.start, newValue!);
                              loadExcel(widget.path);
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
                  value: widget.isVehicle,
                  title: const Text("Veicoli"),
                  onChanged: (bool? value) {
                    setState(() {
                      widget.isVehicle = value!;
                      loadExcel(widget.path);
                    });
                  },
                ),
                CheckboxListTile(
                  value: widget.isPerson,
                  title: const Text("Persone"),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null) {
                        widget.isPerson = value;
                        // ignore: unnecessary_null_comparison
                        if (widget.path != null && widget.path.isNotEmpty) {
                          if (kDebugMode) {
                            print(widget.path);
                          }
                          loadExcel(widget.path);
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
                  value: widget.onlyAnomalies,
                  title: const Text("Mostra solo anomalie"),
                  onChanged: (bool? value) {
                    setState(() {
                      widget.onlyAnomalies = value!;
                      loadExcel(widget.path);
                    });
                  },
                ),
                CheckboxListTile(
                  value: widget.sortByHours,
                  title: const Text("Ordina per ore"),
                  onChanged: (bool? value) {
                    setState(() {
                      widget.sortByHours = value!;
                      loadExcel(widget.path);
                    });
                  },
                ),
                const Divider(
                  color: Colors.black,
                  thickness: 3.0,
                  indent: 15.0,
                  endIndent: 15.0,
                ),
                Text(
                  selectedPerson?.descrizioneDA != null
                      ? "Descrizione ${selectedPerson!.descrizioneDA} : Day: $dayIndx "
                      : "Seleziona persona",
                  textAlign: TextAlign.center,
                ),
                ...[
                  if (selectedPerson != null) ...[
                    for (Hour hour in selectedPerson!.days[dayIndx].hours) ...[
                      ExpansionTile(
                          title: Text(
                            hour.ordinario! + hour.progetto,
                          ),
                          children: [
                            Flex(
                              direction: Axis.horizontal,
                              children: [
                                Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color.fromARGB(255, 30, 89, 138),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                              onPressed: () {},
                                              child: Text(
                                                  "Ord ${hour.ordinario}")),
                                          TextButton(
                                              onPressed: () {},
                                              child:
                                                  Text("Pio ${hour.pioggia}")),
                                          TextButton(
                                              onPressed: () {},
                                              child:
                                                  Text("Mal ${hour.malattia}")),
                                          TextButton(
                                              onPressed: () {},
                                              child: Text("Fer ${hour.ferie}")),
                                        ],
                                      ),
                                    )),
                              ],
                            )
                          ])
                    ]
                  ]
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
