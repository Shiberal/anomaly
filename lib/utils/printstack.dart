import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:anomaly/people/people.dart';
import 'package:anomaly/places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_excel/excel.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintScheme {
  List<Person> people;
  PlacesManager placeManager;
  RangeValues filterHours;
  bool anomalies = false;
  bool outside = false;
  var excel = Excel.createExcel();

  //This is a scheme for priting the elaborated data to a printer

  PrintScheme({
    required this.people,
    required this.placeManager,
    required this.filterHours,
    this.anomalies = false,
    this.outside = false,
  });

  void generate() {
    excel = Excel.createExcel();
    CellStyle cellStyle = CellStyle(
        backgroundColorHex: '#1AFF1A',
        fontFamily: getFontFamily(FontFamily.Calibri));

    Sheet sheet = excel['Sheet1'];
    for (var person in people) {
      sheet.appendRow(
          [person.codiceID, person.descrizioneDA, person.codiceProgetto]);

      for (var day in person.days) {
        sheet.appendRow([day.day, day.ordHours(), day.totalOrdinario]);
      }
    }
    sendToPrinter();
  }

  void save(String path) {
    excel.save(fileName: path);
  }

  String tempSave() {
    var bytes = excel.save();
    final tempDir = getTemporaryDirectory();
    File file = File('${tempDir}/temp.xlsx');
    excel.save(fileName: file.path);
    return file.path;
  }

  void sendToPrinter() {
    String path = tempSave();

    Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Container(
              child: pw.Image(pw.MemoryImage(File(path).readAsBytesSync())),
            );
          }));
      print(path);
      return pdf.save();
    });

    Printing.sharePdf(bytes: File(path).readAsBytesSync());
  }
}
