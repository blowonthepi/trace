import 'package:Trace/tools/encrypt-values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EntryCards extends StatelessWidget {
  final DocumentSnapshot document;
  final List names;
  EntryCards({this.document, this.names});

  @override
  Widget build(BuildContext context) {
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
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
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
}
