import 'package:Trace/screens/add.dart';
import 'package:Trace/screens/add_person.dart';
import 'package:Trace/screens/home.dart';
import 'package:Trace/screens/people.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PageData {
  final String name;
  final Widget page;
  final FloatingActionButton fab;
  final Icon icon;

  /// Stores the data for each page, simplifying code updates
  PageData({this.name, this.page, this.icon, this.fab});

  static List<PageData> getPages(BuildContext context, FirebaseUser user) {
    return [
      new PageData(
        name: "Trace",
        page: new Home(
          user: user,
        ),
        icon: Icon(Icons.home),
        fab: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => Add(uid: user.uid)),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
      new PageData(
        name: "People",
        page: new People(),
        icon: Icon(Icons.people),
        fab: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => AddPerson()),
            );
          },
          child: Icon(Icons.person_add),
        ),
      ),
    ];
  }
}
