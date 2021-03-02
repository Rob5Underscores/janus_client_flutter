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

  //second arg is debug
  JanusClient _janus =
  new HTTPJanusClient('https://janus.rob5underscores.co.uk/api/', false);
  JanusVideoRoom jVR;
  List<RTCVideoView> remotes = [];
  Future _future;

  @override
  void initState() {
    super.initState();
    jVR = new JanusVideoRoom(janus: _janus);
    jVR.room = 1234;
    _future = jVR.setup();
    jVR.addListener(() {
      setState(() {
        this.remotes = jVR.getRemoteVideoViews();
      });
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    if (jVR != null) {
      jVR.close();
    }
    _janus.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Janus VideoRoom Example'),
      ),
      body: new FutureBuilder(
        future: _future,
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