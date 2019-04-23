import 'package:flutter/material.dart';

abstract class OverlayWithWarning extends StatelessWidget {
  Icon get icon;
  String get message;
  Color get messageColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        alignment: FractionalOffset.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            icon,
            Container(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                message,
                style: TextStyle(
                  color: messageColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SearchErrorWidget extends OverlayWithWarning {

  @override
  Icon get icon => Icon(Icons.error_outline, color: Colors.red[300], size: 80.0);

  @override
  String get message => "An error occured";

  @override
  Color get messageColor => Colors.red[300];
}

class SearchIntroWidget extends OverlayWithWarning {

  @override
  Icon get icon => Icon(Icons.info, color: Colors.green[200], size: 80.0);

  @override
  String get message => "Enter a search term to begin";

  @override
  Color get messageColor => Colors.green[100];
}

class EmptyResultWidget extends OverlayWithWarning {

  @override
  Icon get icon => Icon(Icons.warning, color: Colors.yellow[200], size: 80.0);

  @override
  String get message => "No results";

  @override
  Color get messageColor => Colors.yellow[100];
}

class SearchLoadingWidget extends StatelessWidget {
  SearchLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        alignment: FractionalOffset.center,
        child: CircularProgressIndicator(),
      ),
    );
  }
}