import 'package:anomaly/people/days.dart';

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
