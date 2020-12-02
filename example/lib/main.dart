import 'package:flutter/material.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    JanusClient clientFlutter = new HTTPJanusClient('https://janus.rob5underscores.co.uk/api/');

/*    clientFlutter.connect().then((connected) {
      if(connected) {
        print('connected');
      } else {
        print('not connected');
      }
    });*/

    clientFlutter.createSession().then((sess) => {
      if(sess != null) {
        print('created session - back to main')
      } else {
        print(':(')
    }
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on:'),
        ),
      ),
    );
  }
}
