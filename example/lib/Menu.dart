import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter_example/widgets/VideoRoomExample.dart';

class Menu extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text("VideoRoom Example"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return VideoRoomExample(key: UniqueKey());
                }));
              },
            )
          ],
        ));
  }
}
