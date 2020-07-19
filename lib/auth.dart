import 'package:Trace/main.dart';
import 'package:Trace/privacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Auth extends StatefulWidget {
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser user;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey();
  final TextEditingController _email = new TextEditingController();
  final TextEditingController _password = new TextEditingController();
  bool loading = true;
  int currentScreen = 0;

  Widget authScreen() {
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          bottom: 0,
          left: 20,
          right: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Sign in",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: "Your email",
                    alignLabelWithHint: true,
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    alignLabelWithHint: true,
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              RaisedButton(
                child: Text("Sign in".toUpperCase()),
                onPressed: loading ? null : () {
                  authenticate(_email.text, _password.text, 0);
                },
              ),
              FlatButton(
                child: Text("Need an account? Sign up".toUpperCase()),
                onPressed: loading ? null : () {
                  setState(() => currentScreen = 0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget registerScreen() {
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          bottom: 0,
          left: 20,
          right: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Sign up",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: "Your email",
                    alignLabelWithHint: true,
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    alignLabelWithHint: true,
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  text: TextSpan(
                    text: "By tapping \"sign up\" you agree to our ",
                    style: TextStyle(color: Colors.black),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(new MaterialPageRoute(builder: (context) => new PrivacyPolicy()));
                          },
                          child: Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                      )
                    ]
                  ),
                ),
              ),
              RaisedButton(
                child: Text("Sign up".toUpperCase()),
                onPressed: loading ? null : () {
                  authenticate(_email.text, _password.text, 1);
                },
              ),
              FlatButton(
                child: Text("Have an account? Sign in".toUpperCase()),
                onPressed: loading ? null : () {
                  setState(() => currentScreen = 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  userChecker() async {
    setState(() => loading = true);
    try {
      user = await _auth.currentUser();
      if(user.uid != null) {
        Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) => new MyApp()));
      }
    } catch(e) {
      setState(() => currentScreen = 0);
    }
    setState(() => loading = false);
  }

  authenticate(String e, String p, int type) async {
    try {
      setState(() => loading = true);
      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus) {
        currentFocus.unfocus();
      }
      if(type == 0) {
        user = (await _auth.signInWithEmailAndPassword(
          email: e,
          password: p,
        ))
            .user;
      } else {
        user = (await _auth.createUserWithEmailAndPassword(
          email: e,
          password: p,
        ))
            .user;
      }
      setState(() => loading = false);
      userChecker();
    } catch (e) {
      PlatformException error = e;
      print(error.code);
      String errorMsg = "";
      switch(error.code) {
        case "ERROR_EMAIL_ALREADY_IN_USE":
          errorMsg = "This email is already registered. Redirected to Login";
          setState(() {
            currentScreen = 1;
          });
          break;
        case "ERROR_INVALID_EMAIL":
          errorMsg = "Email address is invalid.";
          break;
        case "ERROR_WEAK_PASSWORD":
          errorMsg = "Password is too weak.";
          break;
        default:
          errorMsg = "Something went wrong.";
          break;
      }
      if(errorMsg != "") {
        scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(errorMsg),));
        errorMsg = "";
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    userChecker();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(currentScreen == 0 ? "Sign up" : "Sign in"),
      ),
      body: Center(
        child: ConstrainedBox(
          child: currentScreen == 0 ? registerScreen() : authScreen(),
          constraints: BoxConstraints(
            maxWidth: 700,
          ),
        ),
      ),
    );
  }
}
