import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter_example/Menu.dart';
import 'package:janus_client_flutter_example/widgets/VideoRoomExample.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Menu()
      );
  }
}
