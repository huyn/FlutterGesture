import 'package:flutter/material.dart';
import 'customgesture.dart';

void main() => runApp(CustomGestureApp());

class CustomGestureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
            margin: EdgeInsets.only(left: 0, bottom: 0, right: 0, top: 100),
            child: Stack(
              children: <Widget>[
                Align(
                  child: GestureDetector(
                    onTap: () => print("on Tap 1"),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(color: Colors.pink),
                      margin: EdgeInsets.all(40),
                      child: Text(
                        "hello world bottom",
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
                Align(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => print("on Tap 2"),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(color: Colors.pink),
                      margin: EdgeInsets.all(40),
                      child: Text(
                        "hello world middle",
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
                Align(
                  child: CustomGesture(
                    onDrawGesture: onDrawGesture,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(color: Colors.pink),
                      margin: EdgeInsets.all(40),
                      child: Text(
                        "hello world top",
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                )
              ],
            )));
  }

  void onDrawGesture(bool left) {
    print("onDrawGesture ... $left");
  }
}
