import 'package:Trace/encrypt-values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Trace/add.dart';
import 'package:Trace/add_person.dart';
import 'package:Trace/people.dart';
import 'package:Trace/privacy.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'auth.dart';
import 'export.dart';

void main() {
  runApp(MyApp());
}

final encrypter = Encrypter(AES(EncVals().key));

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trace',
        theme: ThemeData(
          primaryColor: Colors.orange,
          accentColor: Colors.black,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.black,
            textTheme: ButtonTextTheme.primary,
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
          ),
          buttonColor: Colors.black,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cursorColor: Colors.black,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey();
  bool loading = false;
  FirebaseUser user;
  bool home = true;
  int currentHome = 0;
  double width;
  bool userLoggedIn = false;
  List<String> searchQuery = ["All"];
  String searchDate;

  @override
  void initState() {
    userChecker();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  userChecker() async {
    setState(() => loading = true);
    try {
      user = await _auth.currentUser();
      if(user.uid != null) {
        userLoggedIn = true;
      } else {
        Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) => new Auth()));
        userLoggedIn = false;
      }
    } catch(e) {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) => new Auth()));
      userLoggedIn = false;
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(home ? "Trace" : "People"),
        actions: [
          IconButton(
            icon: Icon(Icons.import_export),
            onPressed: exportData,
            tooltip: "Export Data",
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: showSettingsDialog,
          ),
        ],
      ),
      body: main(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: loading ? Container() : FloatingActionButton(
        onPressed: () {
          if(home) {
            Navigator.of(context).push(new MaterialPageRoute(builder: (context) => Add(uid: user.uid)));
          } else {
            Navigator.of(context).push(new MaterialPageRoute(builder: (context) => AddPerson()));
          }
        },
        child: Icon(home ? Icons.add : Icons.person_add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentHome,
        onTap: (index) {
          if(index == 0) {
            setState(() {
              home = true;
              currentHome = index;
            });
          } else {
            setState(() {
              home = false;
              currentHome = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text("Tracing"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            title: Text("People"),
          ),
        ],
      ),
    );
  }

  showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FlatButton.icon(
                    onPressed: exportData,
                    icon: Icon(Icons.import_export),
                    label: Text("Export entries to CSV file")
                  ),
                  Divider(),
                  sheetButton("Sign out", () {
                    _auth.signOut();
                    userChecker();
                  }),
                  Text("Logging out keeps your data stored in the cloud. Tap \"delete account\" if you want to erase records.",
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  Divider(),
                  sheetButton("Privacy Policy", () {
                    Navigator.of(context).push(new MaterialPageRoute(builder: (context) => new PrivacyPolicy()));
                  }),
                  Divider(),
                  sheetButton("Delete Account", () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Are you sure?"),
                            content: Text("By continuing, all your data will be removed from our servers.\nWe will not be able to recover it."),
                            actions: [
                              FlatButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              FlatButton(
                                child: Text("Yes, delete"),
                                onPressed: () {
                                  Firestore.instance.collection('con-'+user.uid).getDocuments().then((snapshot) {
                                    for (DocumentSnapshot ds in snapshot.documents) {
                                      ds.reference.delete();
                                    }
                                  });
                                  Firestore.instance.collection('trace-'+user.uid).getDocuments().then((snapshot) {
                                    for (DocumentSnapshot ds in snapshot.documents) {
                                      ds.reference.delete();
                                    }
                                  });
                                  user.delete();
                                  _auth.signOut();
                                  userChecker();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        }
                    );
                  },),
                  Text("Deleting your account will erase all records you have saved. These are not recoverable.",
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void exportData() {
    ExportData().getData(user.uid);
  }

  Widget main() {
    if(home) {
      return loading ? Center(child: CircularProgressIndicator(),) :
      userLoggedIn == false ? Center(child: CircularProgressIndicator(),) : StreamBuilder(
        stream: Firestore.instance.collection('con-'+user.uid).orderBy("name", descending: false).snapshots(),
        builder: (context, snapshot) {
          // Catch empty data
          if(snapshot.data == null) return Center(child: CircularProgressIndicator());
          if(snapshot.data.documents.isEmpty) {
            setState(() {
              currentHome = 1;
            });
            return showEmptyText();
          }

          // Contact Chip Filter
          List<String> contacts = new List();
          contacts.add("All");
          for(int i = 0; i < snapshot.data.documents.length; i++) {
            DocumentSnapshot document = snapshot.data.documents[i];
            if(document['isEncrypted'] == null) { // Back-encrypt old contact data
              reconfigureEncryption(document, false); // Encryption Maker, false = contact
            }
            try {
              contacts.add(encrypter.decrypt64(document['name'], iv: EncVals().iv));
            } catch (FormatException) {

            }
          }

          // Scrolling chip view
          return Column(
            children: [
              SizedBox(
                height: 50,
                width: width,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: contacts.length,
                  itemBuilder: (context, position) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ChoiceChip(
                        label: Text(contacts[position]),
                        selected: searchQuery.contains(contacts[position]),
                        onSelected: (bool selected) {
                          setState(() {
                            if(selected) {
                              if(contacts[position] == "All") {
                                searchQuery.clear();
                                searchQuery.add("All");
                                searchDate = null;
                              } else {
                                searchQuery.add(contacts[position]);
                                searchQuery.removeWhere((element) => element == "All");
                              }
                            } else {
                              searchQuery.removeWhere((element) => element == contacts[position]);
                              if(searchQuery.isEmpty) {
                                searchQuery.add("All");
                              }
                            }
                          });
                        },
                      ),
                    );
                  }
                ),
              ),
              // Show/hide date search feature
              searchQuery.contains("All") ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FlatButton.icon(
                      icon: Icon(Icons.access_time),
                      label: Text(searchDate == null ? "Search by date" : "Search: $searchDate"),
                      onPressed: () async {
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
                          searchDate = f.format(d);
                        });
                      },
                    ),
                  ),
                  searchDate != null ? FlatButton.icon(
                    icon: Icon(Icons.close),
                    label: Text("Clear date".toUpperCase()),
                    textColor: Colors.black,
                    onPressed: () {
                      setState(() {
                        searchDate = null;
                      });
                    },
                  ) : Container(),
                ],
              ) : Container(),
              Expanded( // main area
                child: StreamBuilder(
                  stream: Firestore.instance.collection("trace-"+user.uid).orderBy("date", descending: true).snapshots(),
                  builder: buildUserList,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return People();
    }
  }

  Widget buildUserList(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if(snapshot.data == null) return Center(child: CircularProgressIndicator());
    if(snapshot.data.documents.isEmpty) {
      setState(() {
        currentHome = 1;
      });
      return showEmptyText();
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: snapshot.data.documents.length,
      itemBuilder: (context, position) {
        DocumentSnapshot document = snapshot.data.documents[position];
        List<Widget> names = new List();
        List<String> searchNames = new List();
        int count = 0;

        if(document['isEncrypted'] == null) {
          reconfigureEncryption(document, true); // Encryption Maker
        }

        for(String eName in document['names']) {
          String name = encrypter.decrypt64(eName, iv: EncVals().iv);
          searchNames.add(name);
          names.add(Padding(
            padding: const EdgeInsets.all(4.0),
            child: Chip(label: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(name),
            )),
          ),);
        }

        for(String n in searchQuery) {
          if(searchNames.contains(n)) {
            count++;
          }
        }
        
        if(!searchQuery.contains("All")) {
          if(count > 0) {
            return showEntries(document, names);
          } else {
            return Container();
          }
        } else {
          if(searchDate != null) {
            String doc = encrypter.decrypt64(document['date'], iv: EncVals().iv).toString().split("at")[0];
            if(searchDate == doc.trim()) {
              return showEntries(document, names);
            } else {
              return Container();
            }
          } else {
            return showEntries(document, names);
          }
        }
      },
    );
  }

  Widget sheetButton(String text, Function fn) {
    return SizedBox(
      width: width,
      child: MaterialButton(
        child: Text(text.toUpperCase()),
        onPressed: fn,
      ),
    );
  }

  reconfigureEncryption(DocumentSnapshot document, bool isEntry) {
    if(isEntry) {
      List<String> names = new List();
      for(String name in document['names']) {
        names.add(encrypter.encrypt(name, iv: EncVals().iv).base64);
      }

      Firestore.instance.collection("trace-"+user.uid).document(document.documentID)
          .updateData({
        'names': names,
        'date': encrypter.encrypt(document['date'], iv: EncVals().iv).base64,
        'location': encrypter.encrypt(document['location'], iv: EncVals().iv).base64,
        'isEncrypted': true,
      });
    } else {
      Firestore.instance.collection("con-"+user.uid).document(document.documentID)
          .updateData({
        'name': encrypter.encrypt(document['name'], iv: EncVals().iv).base64,
        'isEncrypted': true,
      });
    }
  }

  // Card States
  showEntries(DocumentSnapshot document, List names) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 8.0,
        child: ListTile(
          title: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(children: names,),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.date_range),
                        ),
                        Flexible(child: Text(encrypter.decrypt64(document['date'], iv: EncVals().iv))),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.location_on),
                        ),
                        Flexible(child: Text(encrypter.decrypt64(document['location'], iv: EncVals().iv),)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.black,size: 30,),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Are you sure?"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("You are deleting:"),
                        Wrap(children: names,),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.date_range),
                            ),
                            Expanded(child: Text(encrypter.decrypt64(document['date'], iv: EncVals().iv))),
                          ],
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.location_on),
                            ),
                            Expanded(child: Text(encrypter.decrypt64(document['location'], iv: EncVals().iv))),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text("Yes, delete"),
                        onPressed: () {
                          document.reference.delete();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                }
              );
            },
          ),
        ),
      ),
    );
  }

  showEmptyText() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: RichText(
          text: TextSpan(
              text: "No contact entries made. Tap ",
              style: TextStyle(color: Colors.black),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.add),
                ),
                TextSpan(
                  text: " to begin.",
                )
              ]
          ),
        ),
      ),
    );
  }
}
