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


  void hello() async {
    //RTCSessionDescription desc = await pc.createOffer();
    //await pc.setRemoteDescription(rtcSessionDescription);
    //RTCSessionDescription sdp = await pc.createAnswer();

    //print(rtcSessionDescription.toMap());

    // clientFlutter.connect().then((_) =>
    // {
    //   print('connected on main'),
    //   clientFlutter.createSession().then((sess) =>
    //   {
    //     if (sess != null) print('created session on main'),
    //     sess.videoRoomPlugin
    //         .createPublisherHandle(1234)
    //         .then((videoRoomHandle) =>
    //     {
    //       //not creating room (using default 1234)
    //       print('created handle'),
    //       videoRoomHandle.onEvent = ((message) =>
    //       {print('event on main'), print(message)}),
    //
    //       videoRoomHandle.createAnswer(desc).then(
    //               (_) =>
    //           {print('joined publisher'),
    //             print(videoRoomHandle.answer)
    //           })
    //     })
    //   })
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Menu()
      );
  }
}
