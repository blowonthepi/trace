import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'encrypt-values.dart';

class AddPerson extends StatefulWidget {
  @override
  _AddPersonState createState() => _AddPersonState();
}

final encrypter = Encrypter(AES(EncVals().key));

class _AddPersonState extends State<AddPerson> {
  TimeOfDay picked;
  TextEditingController _name = new TextEditingController();
  bool loading = false;
  GlobalKey<ScaffoldState> scaffold = new GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      key: scaffold,
      body: loading ? Center(child: CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.black),),) : Padding(
        padding: const EdgeInsets.only(top: 50.0, bottom: 50.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person_add, color: Theme.of(context).primaryColor, size: 65,),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: TextField(
                      controller: _name,
                      keyboardType: TextInputType.text,
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.words,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        labelText: "Person's Name",
                        labelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 0.0)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 0.0)
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FlatButton(
                        textColor: Colors.black,
                        child: Text("Cancel".toUpperCase()),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RaisedButton(
                        child: Text("Add new contact".toUpperCase()),
                        onPressed: () {
                          addToDb(_name.text);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  addToDb(String name) async {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    setState(() => loading = true);
    await FirebaseAuth.instance.currentUser().then((value) {
      Firestore.instance.collection('con-'+value.uid).document()
          .setData({ 'name': encrypter.encrypt(name, iv: EncVals().iv).base64, 'isEncrypted': true })
          .then((value) {
            Navigator.pop(context);
      }).catchError((e) {
        setState(() => loading = false);
        scaffold.currentState.showSnackBar(new SnackBar(content: Text("Something went wrong."),));
      });
    });
  }

}
