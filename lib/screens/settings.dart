import 'package:Trace/privacy.dart';
import 'package:Trace/tools/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  final Firestore fs = Firestore.instance;
  final FirebaseUser user;
  final FirebaseAuth auth;

  Settings({this.user, this.auth});

  /// Handles the bottom sheet popup
  static showSettings({BuildContext context, FirebaseUser user, FirebaseAuth auth}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Settings(
        user: user,
        auth: auth,
      ),
    );
  }

  Widget sheetButton({Size size, String text, Function fn}) {
    return SizedBox(
      width: size.width,
      child: MaterialButton(
        child: Text(text.toUpperCase()),
        onPressed: fn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      top: false,
      child: SizedBox(
        width: size.width,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton.icon(
                  onPressed: () {
                    ExportData().getData(user.uid);
                  },
                  icon: Icon(Icons.import_export),
                  label: Text("Export entries to CSV file")),
              Divider(),
              sheetButton(
                  size: size,
                  text: "Sign out",
                  fn: () {
                    auth.signOut();
                  }),
              Text(
                "Logging out keeps your data stored in the cloud. Tap \"delete account\" if you want to erase records.",
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              Divider(),
              sheetButton(size: size, text: "Privacy Policy", fn: () {
                Navigator.of(context).push(new MaterialPageRoute(builder: (context) => new PrivacyPolicy()));
              }),
              Divider(),
              sheetButton(
                size: size,
                text: "Delete Account",
                fn: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Are you sure?"),
                          content: Text(
                              "By continuing, all your data will be removed from our servers.\nWe will not be able to recover it."),
                          actions: [
                            TextButton(
                              child: Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Yes, delete"),
                              onPressed: () {
                                fs.collection('con-' + user.uid).getDocuments().then((snapshot) {
                                  for (DocumentSnapshot ds in snapshot.documents) {
                                    ds.reference.delete();
                                  }
                                });
                                fs.collection('trace-' + user.uid).getDocuments().then((snapshot) {
                                  for (DocumentSnapshot ds in snapshot.documents) {
                                    ds.reference.delete();
                                  }
                                });
                                user.delete();
                                auth.signOut();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              Text(
                "Deleting your account will erase all records you have saved. This is a permanent action.",
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
