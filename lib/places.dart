import 'dart:convert';
import 'package:anomaly/people/hours.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PlacesManager {
  List<Place> places = [];
  List<Place> getPlaces() => places;
  void addPlace(Place place) => {
        //if place.id already exists, don't add
        if (!places.any((element) => element.id == place.id)) places.add(place)
      };

  void removePlace(Place place) => {places.remove(place)};

  void clearPlaces() => {places.clear()};

  void sortPlaces() => {places.sort((a, b) => a.name.compareTo(b.name))};

  void savePlaces() {
    File file = File('places.json');
    //clear file
    file.writeAsStringSync('');

    print(file.path);
    for (Place place in places) {
      file.writeAsStringSync(jsonEncode(place.toJson()) + '\n',
          mode: FileMode.append);
    }
  }

  void loadPlaces() {
    File file = File('places.json');
    print(file.absolute.toString());
    //print path of file

    if (file.existsSync()) {
      if (file.lengthSync() == 0) {
        return;
      } else {
        try {
          List<String> lines = file.readAsLinesSync();
          for (String line in lines) {
            // ignore: unnecessary_null_comparison
            if (line == "" || line == null) {
              continue;
            }
            Place place = Place.fromJson(jsonDecode(line));
            places.add(place);
          }
        } catch (e) {
          return;
        }
      }
    }
  }

  get placesCount => places.length;

  isOutside(List<Hour> hours) {
    for (Hour hour in hours) {
      if (hour.totalHours - int.parse(hour.ferie!) > 0) {
        print(hour.progettoID);
        for (Place place in places) {
          print("${hour.progettoID} : ${place.id}");
          if (hour.progettoID == place.name) {
            if (place.isOutside) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }
}

class Place {
  String name;
  String id;
  bool isOutside;
  Place(this.name, this.id, this.isOutside);

  static Place fromJson(jsonDecode) {
    return Place(jsonDecode['name'], jsonDecode['id'], jsonDecode['isOutside']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'isOutside': isOutside,
    };
  }
}

class Places extends StatefulWidget {
  const Places(this.placesManager, {super.key});
  @override
  State<Places> createState() => _PlacesState();
  final PlacesManager placesManager;
}

class _PlacesState extends State<Places> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: listTilePlace(),
    );
  }

  List<Widget> listTilePlace() {
    if (widget.placesManager.placesCount == 0) {
      return [const Text("No places yet")];
    }

    return [
      for (Place place in widget.placesManager.getPlaces())
        ListTile(
          title: Text(place.name),
          subtitle: Text(place.id),
          leading: Checkbox(
              value: place.isOutside,
              onChanged: (value) {
                setState(() {
                  place.isOutside = value!;
                  widget.placesManager.savePlaces();
                });
              }),
        )
    ];
  }
}
