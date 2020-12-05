import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    hello();
  }

  void hello() async {
    JanusClient clientFlutter =
    new HTTPJanusClient('https://janus.rob5underscores.co.uk/api/');
    RTCPeerConnection pc = await createPeerConnection({
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan'
    });

    MediaStream _localStream;
    _localRenderer.initialize();
    await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': true})
        .then((ls) => {
          _localStream = ls,
      _localRenderer.srcObject = ls,
      setState(() {ready = true;})
    });
    await pc.addTransceiver(track:_localStream.getAudioTracks()[0], init:RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv, streams:[_localStream]));

    await pc.addTransceiver(
        track: _localStream.getVideoTracks()[0],
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendOnly,
          streams: [_localStream],
          sendEncodings: [
            // for firefox order matters... first high resolution, then scaled resolutions...
            RTCRtpEncoding(
              rid: 'f',
              maxBitrate: 900000,
              numTemporalLayers: 3,
            ),
            RTCRtpEncoding(
              rid: 'h',
              numTemporalLayers: 3,
              maxBitrate: 300000,
              scaleResolutionDownBy: 2.0,
            ),
            RTCRtpEncoding(
              rid: 'q',
              numTemporalLayers: 3,
              maxBitrate: 100000,
              scaleResolutionDownBy: 4.0,
            ),
          ],
        ));


    RTCSessionDescription desc = await pc.createOffer();
    //await pc.setRemoteDescription(rtcSessionDescription);
    //RTCSessionDescription sdp = await pc.createAnswer();

    //print(rtcSessionDescription.toMap());

    clientFlutter.connect().then((_) =>
    {
      print('connected on main'),
      clientFlutter.createSession().then((sess) =>
      {
        if (sess != null) print('created session on main'),
        sess.videoRoomPlugin
            .createPublisherHandle(1234)
            .then((videoRoomHandle) =>
        {
          //not creating room (using default 1234)
          print('created handle'),
          videoRoomHandle.onEvent = ((message) =>
          {print('event on main'), print(message)}),

          videoRoomHandle.createAnswer(desc).then(
                  (_) =>
              {print('joined publisher'),
                print(videoRoomHandle.answer)
              })
        })
      })
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
          child: ready ? new RTCVideoView(
              _localRenderer) : Text('Loading...'),
        ),
      ),
    );
  }
}
