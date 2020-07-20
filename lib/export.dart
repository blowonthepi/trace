import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class ExportData {
  String filePath;

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.absolute.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    filePath = '$path/data.csv';
    return File('$path/data.csv').create();
  }

  void getData(String uid) {
    List<List<dynamic>> rows = List<List<dynamic>>();
    rows.add([
      "Name",
      "Date & Time (dd/mm/yyyy)",
      "Location"
    ]);
    Firestore.instance.collection("trace-"+uid).orderBy("date", descending: true).snapshots().listen((snapshot) {
      snapshot.documents.forEach((element) {
        List<dynamic> row = List<dynamic>();
        row.add(element.data['names'].toString());
        row.add(element.data['date']);
        row.add(element.data['location']);
        rows.add(row);
      });
    });
  }
}
