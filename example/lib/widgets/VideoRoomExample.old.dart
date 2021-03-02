import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';

class VideoRoomExample extends StatefulWidget {
  VideoRoomExample({Key key}) : super(key: key);

  @override
  _VideoRoomExampleState createState() => _VideoRoomExampleState();
}

class _VideoRoomExampleState extends State<VideoRoomExample> {

  RTCVideoRenderer localRenderer = new RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};

  VideoRoomPublisher publisher;

  Session session;

  //this is 1-1 for each publisher there is (in the future it might be
  // possible to have 1 subscription for all publishers).
  //feedid / subscription
  Map<int,VideoRoomListener> subscriptions = {};


  int room = 1234;

  bool isSetup = false;

  JanusClient janus = new HTTPJanusClient(
      'https://janus.rob5underscores.co.uk/api/');

  @override
  void initState() {
    super.initState();
  }

  void _onSessionEvent() {
    print('received session event in example');
  }

  void _onWebrtcUp(Map test) {
    print('received webrtcup event in example');
    print(test);
  }

  void _onMedia(Map test) {
    print('received media event in example');
    print(test);
  }

  void _onHangup() {
    print('received hangup event in example');
  }

  void _onSlowlink() {
    print('received slowlink event in example');
  }

  void _onDetached() {
    print('received detatched event in example');
  }

  void _onVideoRoomEvent(Map event) {
    print('received videroom event in example');
    print(event);
    var data = event['plugindata']['data'];
    if(data['videoroom'] == 'event') {
      if(data['publishers'] != null) {
        checkPublishers(data['publishers']);
      }
    }
  }

  void checkPublishers(List publishers) {
    for(var p in publishers) {
      if(!subscriptions.containsKey(p['id'])) {
        print('publisher to listen to: $p');
        session.videoRoomPlugin.listenFeed(room, p['id'])
            .then((listen) => {
          print('created listener handle'),
          subscriptions[p['id']] = listen,
          listen.pc().then((pc) => {
            pc.onTrack = (track) => {
              print('list ontrack in example'),
              addRemoteRenderer(p['id'], track.streams[0])
            },
            subscriptions[p['id']] = listen,
            listen.setRemoteAnswer()
          })
        });
      }
    }
  }

  void _onTrickle() {
    print('received trickle event in example');
  }

  bool registerEvents(VideoRoomHandle handle) {
    this.session.onEvent = _onSessionEvent;
    //if we create a new handle, we have to re-register these events;
    handle.onWebrtcUp = _onWebrtcUp;
    handle.onMedia = _onMedia;
    handle.onHangup = _onHangup;
    handle.onSlowlink = _onSlowlink;
    handle.onDetached = _onDetached;
    handle.onEvent = _onVideoRoomEvent;
    handle.onTrickle = _onTrickle;
    //need to return a value so that final chained future hasData
    return true;
  }

  Future<void> startSetup() {
    if(isSetup) return Future.value(true);
    return setup();
  }

  Future<void> updateSubscribers() {
    return session.videoRoomPlugin.getFeeds(room).then((participants) => {
        participants.forEach((p) {
          if(!subscriptions.keys.contains(p)) {
            print('publisher to listen to: $p');
            session.videoRoomPlugin.listenFeed(room, p)
                .then((listen) => {
                  print('created listener handle'),
              subscriptions[p] = listen,
                  listen.pc().then((pc) => {
                    pc.onTrack = (track) => {
                      print('list ontrack in example'),
                      addRemoteRenderer(p, track.streams[0])
                    },
                    subscriptions[p] = listen,
                    listen.setRemoteAnswer()
                  })
                });
          }
        })});
  }

  void addRemoteRenderer(int id, MediaStream ms) {
    if(remoteRenderers.containsKey(id)) return;
    RTCVideoRenderer newRend = new RTCVideoRenderer();
    newRend.initialize().then((_) => {{
      newRend.srcObject = ms
    }}).then((_) => {
      setState(() {
        this.remoteRenderers[id] = newRend;
      })
    });
  }

  Future<void> setup() {
    localRenderer.initialize();
    MediaStream localStream;
    return janus.connect()
        .then((_) => janus.createSession())
        .then((sess) => this.session = sess)
        .then((_) =>
        navigator.mediaDevices.getUserMedia({'audio': true, 'video': {
          'mandatory': {
            'minWidth':
            '640', // Provide your own width, height and frame rate here
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        }}))
        .then((ls) => localStream = ls)
        .then((_) => localRenderer.srcObject = localStream)
        .then((_) => publishOwnFeed(localStream))
        .then((_) => registerEvents(this.publisher))
        //.then((_) => updateSubscribers())
        .then((_) => this.isSetup = true)
        .then((_) => Future.value(true));
  }

  Future<void> publishOwnFeed(MediaStream localStream) {
    print('called');
    return session.videoRoomPlugin.createPublisherHandle(room)
        .then((VideoRoomPublisher pH) => this.publisher = pH)
        .then((_) => this.publisher.addLocalMedia(localStream))
        .then((_) => this.publisher.createAnswer())
        .then((res) => {
          if(res['publishers'] != null) {
            checkPublishers(res['publishers'])
          }
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    janus.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Janus VideoRoom Example'),
      ),
      body: new FutureBuilder(
        future: startSetup(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          if (!snapshot.hasData) return new Text('Loading...');
          return Column(children: <Widget>[
            Row(children: [new Container(child:new RTCVideoView(localRenderer, mirror: true), width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4)]),
            if(remoteRenderers.length > 0) Row(children: remoteRenderers.values.map((rend) => new Container(child:new RTCVideoView(rend), width: MediaQuery.of(context).size.width/4, height: MediaQuery.of(context).size.height/3)).toList())
            //if(show) Row(children: [new Container(child:new RTCVideoView(rtcVideoRenderer), width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4)]),

          ]
          );
        },
      ),
        floatingActionButton: new FloatingActionButton(
            onPressed: updateSubscribers,
            tooltip: 'Refresh',
            backgroundColor: (Colors.green),
            child: new Icon(Icons.phone)));
  }

}