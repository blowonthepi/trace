import 'package:Trace/tools/encrypt-values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class People extends StatefulWidget {
  @override
  _PeopleState createState() => _PeopleState();
}

final encrypter = Encrypter(AES(EncVals().key));

class _PeopleState extends State<People> {
  FirebaseUser user;
  bool loading = true;

  initFirebase() async {
    user = await FirebaseAuth.instance.currentUser();
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    initFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(child: CircularProgressIndicator(),) : StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('con-'+user.uid).orderBy("name", descending: false).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return new Text('Error: ${snapshot.error}');
        }
        if(snapshot.data == null) return Center(child: CircularProgressIndicator());
        if(snapshot.data.documents.isEmpty) {
          // Handle no data
          return Center(
            child: RichText(
              text: TextSpan(
                text: "No name entries made. Tap ",
                style: TextStyle(color: Colors.black),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.person_add),
                  ),
                  TextSpan(
                    text: " to begin.",
                  )
                ]
              ),
            ),
          );
        }
        return new ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: snapshot.data.documents.map((DocumentSnapshot document) {
            String name = encrypter.decrypt64(document['name'], iv: EncVals().iv);
            return Column(
              children: [
                new ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Text(name[0], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(name),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Theme.of(context).accentColor,),
                    onPressed: () => document.reference.delete(),
                  ),
                ),
                Divider(color: Colors.grey[700],),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}