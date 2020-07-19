import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {

  Future<void> _launchLink(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Privacy Policy", style: Theme.of(context).textTheme.headline2,),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(text: "We hold personal information inputted by you, including information about your:\n"),
                  TextSpan(text: "  • contacts names\n"),
                  TextSpan(text: "  • location (only what is manually typed)\n"),
                  TextSpan(text: "  • your email address (for login purposes)\n"),
                  WidgetSpan(child: SizedBox(height: 50,)),
                  TextSpan(text: "All information we store has been explicitly provided by the user (you), we do not collect any information in the background.\n"),
                  WidgetSpan(child: SizedBox(height: 50,)),
                  TextSpan(text: "We collect your personal information in order to:\n"),
                  TextSpan(text: "  • keep a list of your contacts during COVID Alert Level 2 in New Zealand.\n"),
                  TextSpan(text: "  • We keep your information for as long as they have an account (accounts can be deleted) at which point we securely destroy it by deleting all personal records in our database.\n"),
                  TextSpan(text: "  • You have the right to ask for a copy of any personal information we hold about you, and to ask for it to be corrected if you think it is wrong. If you’d like to ask for a copy of your information, or to have it corrected, please contact us at "),
                  WidgetSpan(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _launchLink("mailto:hello@liamedwardsnz.com?subject=COVIDTrace:%20PI%20REQUEST&body=Please%20include%20your%20account%20email%20address");
                        },
                        child: Text("hello@liamedwardsnz.com", style: TextStyle(color: Colors.black, fontSize: 16),),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}