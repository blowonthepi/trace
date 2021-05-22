import 'package:Trace/screens/settings.dart';
import 'package:Trace/tools/export.dart';
import 'package:Trace/tools/page_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GestureDetector(
      onTap: () {
        // Remove focus from system keyboard when user taps
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
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future _future;
  FirebaseUser user;

  List<PageData> pages;

  // start at 0 for home
  int _currentIndex = 0;

  @override
  void initState() {
    _future = userChecker();
    // Populate the pages list
    pages = PageData.getPages(context, user);
    super.initState();
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    if (oldWidget != widget) {
      // for pages to update with hot reloads
      pages = PageData.getPages(context, user);
    }
    super.didUpdateWidget(oldWidget);
  }

  /// Checks apps current auth state
  Future<bool> userChecker() async {
    try {
      user = await _auth.currentUser();
      if (user.uid != null) {
      } else {
        Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) => new Auth()));
      }
    } catch (e) {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) => new Auth()));
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Basically a splash screen
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // Actual App Scaffold
        return Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            title: Text(pages[_currentIndex].name),
            actions: [
              IconButton(
                icon: Icon(Icons.import_export),
                onPressed: () => ExportData().getData(user.uid),
                tooltip: "Export Data",
              ),
              IconButton(
                icon: Icon(Icons.info),
                onPressed: () => Settings.showSettings(
                  context: context,
                  user: user,
                  auth: _auth,
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              for (PageData page in pages) page.page,
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: pages[_currentIndex].fab,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              for (PageData p in pages)
                BottomNavigationBarItem(
                  icon: p.icon,
                  label: p.name,
                ),
            ],
          ),
        );
      },
    );
  }
}
