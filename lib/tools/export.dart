import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

import 'encrypt-values.dart';

class ExportData {
  final encrypter = Encrypter(AES(EncVals().key));

  String dirPath, fileName;

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.absolute.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    dirPath = path;
    String datetime = DateFormat("dd-mm-yyyy – kk.mm").format(DateTime.now());
    fileName = "TRACE $datetime.csv";
    return File("$dirPath/$fileName").create();
  }

  void getData(String uid) {
    List<List<dynamic>> rows = [];
    rows.add([
      "Name",
      "Date & Time (dd/mm/yyyy)",
      "Location"
    ]);
    Firestore.instance.collection("trace-"+uid).orderBy("date", descending: true).snapshots().listen((snapshot) {
      snapshot.documents.forEach((element) {
        List<dynamic> row = [];
        List names = [];
        for(String n in element.data['names']) {
          names.add(encrypter.decrypt64(n, iv: EncVals().iv));
        }
        row.add(names.join(', '));
        row.add(encrypter.decrypt64(element.data['date'], iv: EncVals().iv));
        row.add(encrypter.decrypt64(element.data['location'], iv: EncVals().iv));
        rows.add(row);
      });
    });

    setFile(rows);
  }

  void setFile(List<List<dynamic>> rows) async {
    File f = await _localFile;

    String csv = const ListToCsvConverter().convert(rows);
    f.writeAsString(csv);

    ShareExtend.share("$dirPath/$fileName", "file").timeout(Duration(seconds: 5), onTimeout: () => f.delete());
  }
}
