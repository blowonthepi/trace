import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_select/smart_select.dart';

class Add extends StatefulWidget {
  Add({this.uid});

  final String uid;
  @override
  _AddState createState() => _AddState(uid);
}

class _AddState extends State<Add> {
  _AddState(this.uid);

  String mergedDateTime;
  final String uid;
  bool loading = true;

  GlobalKey<ScaffoldState> scaffold = new  GlobalKey();

  List<String> names = [];
  List<SmartSelectOption<String>> people = new List();
  TextEditingController _location = new TextEditingController();

  getPeople() {
    Firestore.instance
        .collection("con-"+uid)
        .snapshots()
        .listen((data) =>
    data.documents.forEach((doc) {
      people.add(SmartSelectOption<String>(value: doc.data['name'], title: doc.data['name']));
    }));
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    getPeople();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: scaffold,
      appBar: AppBar(
        title: Text("New Trace Entry"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () {
              addRecord();
            },
          ),
        ],
      ),
      body: loading ? Center(child: CircularProgressIndicator(),) : Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: const Icon(Icons.people),
              ),
              title: SmartSelect<String>.multiple(
                modalType: SmartSelectModalType.bottomSheet,
                title: 'People',
                isTwoLine: true,
                value: names,
                options: people,
                onChange: (val) => setState(() => names = val),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: mergedDateTime != null ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(mergedDateTime),
                  ),
                  FlatButton(
                    child: Text("New Date/Time"),
                    onPressed: () {
                      selectTime(context);
                    },
                  ),
                ],
              ) : RaisedButton(
                child: Text("Select Date/Time"),
                onPressed: () {
                  selectTime(context);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: TextField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  selectTime(BuildContext context) async {
    TimeOfDay t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.orange,
            accentColor: Colors.orangeAccent,
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
            ),
          ),
          child: child,
        );
      }
    );
    DateTime d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
            ),
          ),
          child: child,
        );
      }
    );
    final f = new DateFormat('dd/MM/yyyy');
    setState(() {
      mergedDateTime = f.format(d)+" at "+t.format(context);
    });
  }

  addRecord() async {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    setState(() => loading = true);
    await FirebaseAuth.instance.currentUser().then((value) {
      Firestore.instance.collection('trace-'+value.uid).document()
          .setData({
        'names': names,
        'date': mergedDateTime,
        'location': _location.text,
      }).then((value) {
        Navigator.pop(context);
      }).catchError((e) {
        print(e.toString());
        setState(() => loading = false);
        scaffold.currentState.showSnackBar(new SnackBar(content: Text("Something went wrong."),));
      });
    });
  }

}
