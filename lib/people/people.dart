import 'package:anomaly/people/days.dart';
import 'package:anomaly/people/hours.dart';
import 'package:anomaly/places.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_excel/excel.dart';

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
    int total = 0;
    for (Day day in days) {
      total += day.countAnomalies(min, max);
    }
    return total;
  }

  void sortDays() {
    days.sort((a, b) => b.totalHours.compareTo(a.totalHours));
  }

  void sortHours() {
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
}

class PersonDataSource extends DataTableSource {
  PersonDataSource(this.persons, this.filterHours, this.selectedPerson,
      this.updateSelectedPerson);

  final List<Person> persons;
  final RangeValues filterHours;
  void Function(Person person, int day) updateSelectedPerson;

  Person? selectedPerson;

  @override
  DataRow? getRow(int index) {
    final Person person = persons[index];

    return DataRow(
      cells: <DataCell>[
        DataCell(Text(person.descrizioneDA)),
        DataCell(Text(person.codiceID)),
        ...[
          for (Day day in person.days) ...[
            DataCell(Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: day.isAnomalyColor(
                      filterHours.start.toInt(), filterHours.end.toInt())),
              child: Flex(direction: Axis.horizontal, children: [
                Expanded(
                  child: Tooltip(
                    message: day.ordHours(),
                    child: TextButton(
                        onPressed: () {
                          updateSelectedPerson(person, day.day);
                        },
                        child: Text(day.totalOrdinario.toString())),
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: day.pioHours(),
                    child: TextButton(
                        onPressed: () {
                          updateSelectedPerson(
                              person, day.day); // Call the callback
                        },
                        child: Text(day.totalPioggia.toString())),
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: day.malHours(),
                    child: TextButton(
                        onPressed: () {
                          updateSelectedPerson(person, day.day);
                        },
                        child: Text(day.totalMalattia.toString())),
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: day.ferHours(),
                    child: TextButton(
                        onPressed: () {
                          updateSelectedPerson(person, day.day);
                        },
                        child: Text(day.totalFerie.toString())),
                  ),
                ),
              ]),
            )),
          ]
        ]
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => persons.length;

  @override
  int get selectedRowCount => 0;
}

List<Person> extractPeople(
    Excel excel,
    String sheetName,
    bool isVehicle,
    bool isPerson,
    RangeValues filterHours,
    bool onlyAnomalies,
    bool sortByHours,
    PlacesManager placesManager) {
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
      placesManager
          .addPlace(Place(row[0]?.value ?? '', row[6]?.value ?? '', false));

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
        if (kDebugMode) {
          // ignore: avoid_print
          print("Error processing day data: $e");
        }
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
