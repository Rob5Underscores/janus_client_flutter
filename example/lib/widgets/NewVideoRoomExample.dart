import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';

class NewVideoRoomExample extends StatefulWidget {
  NewVideoRoomExample({Key key}) : super(key: key);

  @override
  _NewVideoRoomExampleState createState() => _NewVideoRoomExampleState();
}

class _NewVideoRoomExampleState extends State<NewVideoRoomExample> {

  RTCVideoRenderer localRenderer = new RTCVideoRenderer();

  bool isSetup = false;
  JanusVideoRoom jVR;
  int room = 1234;

  List<RTCVideoView> remotes = [];

  JanusClient janus = new HTTPJanusClient(
      'https://janus.rob5underscores.co.uk/api/');

  @override
  void initState() {
    super.initState();
  }

  Future<void> setup() {
    if(isSetup) return Future.value(true);
    localRenderer.initialize();
    MediaStream localStream;
    return navigator.mediaDevices.getUserMedia({'audio': true, 'video': true})
        .then((ls) => localStream = ls)
        .then((_) => {
          localRenderer.srcObject = localStream,
      localRenderer.muted = true
        })
    .then((_) => janus.connect())
    .then((_) => jVR = new JanusVideoRoom(janus:janus, room:1234))
    .then((_) => jVR.start(localStream))
    .then((_) => jVR.addListener(() {
      print('Updating VideoRoom');
      setState(() {
        this.remotes = jVR.getRemoteVideoViews();
      });
    }))
    .then((_) => this.isSetup = true)
    .then((_) => Future.value(true));
  }

  @override
  void deactivate() {
    super.deactivate();
    if(jVR != null) {
      jVR.close();
    }
    janus.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Janus VideoRoom Example'),
      ),
      body: new FutureBuilder(
        future: setup(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          if (!snapshot.hasData) return new Text('Loading...');
          return Column(children: <Widget>[
            Row(children: [new Container(child:new RTCVideoView(localRenderer, mirror: true), width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4)]),
            if(remotes.length > 0) Row(children: remotes.map((view) => new Container(child:view, width: MediaQuery.of(context).size.width/4, height: MediaQuery.of(context).size.height/3)).toList())
          ]
          );
        },
      ));
  }

}