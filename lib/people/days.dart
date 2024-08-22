import 'package:anomaly/people/hours.dart';
import 'package:flutter/material.dart';

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

  get isMinAnomaly {
    return totalHours <= 0;
  }

  void sortHours() {
    hours.sort((a, b) => b.totalHours.compareTo(a.totalHours));
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

  get totalOrdinario {
    double total = 0;
    for (Hour hour in hours) {
      total += double.parse(hour.ordinario ?? '0');
    }
    return total;
  }

  get totalMalattia {
    double total = 0;
    for (Hour hour in hours) {
      total += double.parse(hour.malattia ?? '0');
    }
    return total;
  }

  get totalFerie {
    double total = 0;
    for (Hour hour in hours) {
      total += double.parse(hour.ferie ?? '0');
    }
    return total;
  }

  get totalPioggia {
    double total = 0;
    for (Hour hour in hours) {
      total += double.parse(hour.pioggia ?? '0');
    }
    return total;
  }

  String ordHours() {
    try {
      String out = '';

      for (Hour hour in hours) {
        if (int.tryParse(hour.ordinario!)! > 0) {
          out += '${hour.ordinario!} ${hour.progetto}\n';
        }
      }
      return out;
    } catch (e) {
      return '';
    }
  }

  isAnomalyColor(min, max) {
    if (totalHours > max) {
      return const Color.fromARGB(255, 255, 83, 26);
    }
    if (totalHours < min) {
      return const Color.fromARGB(255, 251, 17, 0);
    } else {
      return Colors.grey[800];
    }
  }

  pioHours() {
    String out = '';
    for (Hour hour in hours) {
      if (int.tryParse(hour.pioggia!)! > 0) {
        out += '${hour.pioggia!} ${hour.progetto}\n';
      }
    }
    return out;
  }

  malHours() {
    String out = '';
    for (Hour hour in hours) {
      if (int.tryParse(hour.malattia!)! > 0) {
        out += '${hour.malattia!} ${hour.progetto}\n';
      }
    }
    return out;
  }

  ferHours() {
    String out = '';
    for (Hour hour in hours) {
      if (int.tryParse(hour.ferie!)! > 0) {
        out += '${hour.ferie!} ${hour.progetto}\n';
      }
    }
    return out;
  }
}
