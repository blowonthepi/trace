import 'package:Trace/screens/home/entry_card.dart';
import 'package:Trace/tools/encrypt-values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  final FirebaseUser user;

  Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Default is "All" to show all entries
  final List<String> searchQuery = ["All"];
  String searchDate;

  noEntriesMsg() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: RichText(
          text: TextSpan(text: "No contact entries made. Tap", style: TextStyle(color: Colors.black), children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.add),
              ),
            ),
            TextSpan(
              text: "to begin.",
            )
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: Firestore.instance.collection('con-' + widget.user.uid).orderBy("name", descending: false).snapshots(),
      builder: (context, snapshot) {
        // Catch empty data
        if (snapshot.data == null) return Center(child: CircularProgressIndicator());
        if (snapshot.data.documents.isEmpty) return noEntriesMsg();

        // Contact Chip Filter
        List<String> contacts = [];
        contacts.add("All");
        for (int i = 0; i < snapshot.data.documents.length; i++) {
          DocumentSnapshot document = snapshot.data.documents[i];
          try {
            contacts.add(encrypter.decrypt64(document['name'], iv: EncVals().iv));
          } catch (FormatException) {}
        }

        // Scrolling chip view
        return Column(
          children: [
            SizedBox(
              height: 50,
              width: size.width,
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
                            if (selected) {
                              if (contacts[position] == "All") {
                                searchQuery.clear();
                                searchQuery.add("All");
                                searchDate = null;
                              } else {
                                searchQuery.add(contacts[position]);
                                searchQuery.removeWhere((element) => element == "All");
                              }
                            } else {
                              searchQuery.removeWhere((element) => element == contacts[position]);
                              if (searchQuery.isEmpty) {
                                searchQuery.add("All");
                              }
                            }
                          });
                        },
                      ),
                    );
                  }),
            ),
            // Show/hide date search feature
            searchQuery.contains("All")
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
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
                                });
                            final f = new DateFormat('dd/MM/yyyy');
                            setState(() {
                              searchDate = f.format(d);
                            });
                          },
                        ),
                      ),
                      searchDate != null
                          ? TextButton.icon(
                              icon: Icon(Icons.close),
                              label: Text("Clear date".toUpperCase()),
                              style: TextButton.styleFrom(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  searchDate = null;
                                });
                              },
                            )
                          : Container(/* This when no date is specified */),
                    ],
                  )
                : Container(/* This when "All" is filter choice */),
            Expanded(
              // Entries
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection("trace-" + widget.user.uid)
                    .orderBy("date", descending: true)
                    .snapshots(),
                builder: buildUserList,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildUserList(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    // When waiting, show progress indicator
    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
    // When done, but nothing returned show empty message
    if (snapshot.data == null || snapshot.data.documents.isEmpty) return noEntriesMsg();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: snapshot.data.documents.length,
      itemBuilder: (context, position) {
        DocumentSnapshot document = snapshot.data.documents[position];
        // Widgets being returned
        List<Widget> names = [];
        int nameCount = 0;

        for (String eName in document['names']) {
          String name = encrypter.decrypt64(eName, iv: EncVals().iv);
          // Count number of name matches
          if (searchQuery.contains(name)) nameCount++;
          names.add(
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Chip(
                label: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(name),
                ),
              ),
            ),
          );
        }

        if (searchQuery.contains("All")) {
          // Show all results
          if (searchDate == null) {
            // Show all dates
            return EntryCards(document: document, names: names);
          } else {
            // Show if query date matches
            String doc = encrypter.decrypt64(document['date'], iv: EncVals().iv).toString().split("at")[0];
            if (searchDate == doc.trim()) {
              return EntryCards(document: document, names: names);
            }
          }
        } else if (nameCount > 0) {
          // Show if there is at least 1 matching name
          return EntryCards(document: document, names: names);
        }
        return Container();
      },
    );
  }
}
