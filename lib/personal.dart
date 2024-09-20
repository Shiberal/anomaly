// ignore_for_file: file_names

import 'dart:io';
import 'package:anomaly/people/hours.dart';
import 'package:anomaly/people/people.dart';
import 'package:anomaly/places.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_excel/excel.dart';
import 'package:anomaly/utils/printstack.dart';

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
  late PersonDataSource personDataSource;
  late int page;

  @override
  void initState() {
    selectedPerson = (widget.people.isNotEmpty ? widget.people[0] : null);
    dayIndx = 0;
    page = 0;

    // Initialize personDataSource with the initial data
    personDataSource = PersonDataSource(
      widget.people,
      widget.filterHours,
      selectedPerson,
      updateSelectedPerson,
      widget.placesManager,
    );

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
      // ignore: prefer_typing_uninitialized_variables
      late var bytes;
      // ignore: prefer_typing_uninitialized_variables
      late var excel;
      late List<Person> extractedPeople;

      setState(() {
        bytes = File(path).readAsBytesSync();
        excel = Excel.decodeBytes(bytes);
        extractedPeople = extractPeople(
            excel,
            'Sheet',
            widget.isVehicle,
            widget.isPerson,
            widget.filterHours,
            widget.onlyAnomalies,
            widget.sortByHours,
            widget.placesManager);
        widget.people = extractedPeople;
      });
    }

    final outerController = ScrollController();
    final innerController = ScrollController();
    final pageController = ScrollController();

    return Flex(
      direction: Axis.horizontal,
      children: [
        Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.only(top: 124.0),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                itemBuilder: (context, index) {
                  if ((page) + index >= (widget.people.length)) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                      minTileHeight: 50,
                      title: Text(
                        widget.people[(page) + index].descrizioneDA,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ), // display name
                      // if odd color is lightgrey, if even color is grey
                      tileColor: index % 2 == 0
                          ? const Color.fromARGB(255, 57, 59, 60)
                          : const Color.fromARGB(255, 30, 31, 31),
                      onTap: () {
                        //on tap copy the id to the clipboard
                        Clipboard.setData(ClipboardData(
                            text: widget.people[(page) + index].codiceID));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Copiato ${widget.people[(page) + index].codiceID}"),
                          ),
                        );
                      });
                },
              ),
            )),
        Expanded(
          flex: 7,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                  flex: 3,
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        final offset = event.scrollDelta.dy;

                        innerController.jumpTo(innerController.offset + offset);
                        outerController.jumpTo(outerController.offset - offset);
                      }
                    },
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: innerController,
                      child: PaginatedDataTable(
                          controller: pageController,
                          onPageChanged: (value) {
                            setState(() {
                              page = value;
                              print("page: $page");
                            });
                          },
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
                                                    textAlign:
                                                        TextAlign.center)),
                                            const Expanded(
                                                flex: 2,
                                                child: Text("Fer",
                                                    textAlign:
                                                        TextAlign.center)),
                                          ]),
                                    ))
                            ]
                          ]),
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.blue,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                TextButton(
                    onPressed: () {
                      var scheme = PrintScheme(
                          people: widget.people,
                          placeManager: widget.placesManager,
                          filterHours: widget.filterHours);
                      scheme.generate();
                    },
                    child: const Text("Salva Excel")),
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
                        print("No file selected");
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
                      ? "Descrizione ${selectedPerson!.descrizioneDA} : Day: ${dayIndx + 1} "
                      : "Seleziona persona",
                  textAlign: TextAlign.center,
                ),
                ...[
                  if (selectedPerson != null) ...[
                    for (Hour hour in selectedPerson!.days[dayIndx].hours) ...[
                      ExpansionTile(
                          title: Text(
                            hour.ordinario! + " " + hour.progetto,
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
                                              onPressed: () {
                                                //copy the code to clipboard

                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        "${hour.progettoID}"));

                                                // toast

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Copiato ${hour.progettoID}"),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                  "Ord ${hour.ordinario}")),
                                          TextButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        "${hour.progettoID}"));

                                                // toast

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Copiato ${hour.progettoID}"),
                                                  ),
                                                );
                                              },
                                              child:
                                                  Text("Pio ${hour.pioggia}")),
                                          TextButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        "${hour.progettoID}"));

                                                // toast

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Copiato ${hour.progettoID}"),
                                                  ),
                                                );
                                              },
                                              child:
                                                  Text("Mal ${hour.malattia}")),
                                          TextButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        "${hour.progettoID}"));

                                                // toast

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Copiato ${hour.progettoID}"),
                                                  ),
                                                );
                                              },
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
