import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/listener.dart';
import 'package:janus_client_flutter/src/session.dart';

class JanusVideoRoom with ChangeNotifier {
  JanusClient janus;
  int room = 1234;
  MediaStream localStream, displayMediaStream;

  Session session;

  Map<int, RTCVideoRenderer> remotes = {};
  RTCVideoRenderer local = new RTCVideoRenderer();

  //this is 1-1 for each publisher there is (in the future it might be
  // possible to have 1 subscription for all publishers).
  //feedid / subscription
  Map<int, VideoRoomListener> subscriptions = {};
  VideoRoomPublisher publisher, screenSharePublisher;

  bool isSetup = false,
      isMuted = false,
      isCameraOff = false,
      isFlipped = false,
      isSharingScreen = false,
      supportsFlipping = false,
      _publish = true;

  JanusVideoRoom({this.janus});

  Future<bool> setup([bool publish = true]) {
    if(publish != null) {
      this._publish = publish;
    }
    if (isSetup) return Future.value(true);
    this.isSetup = true;
    return setLocalStream()
        //returns true of already connected
        .then((_) => janus.connect())
        .then((_) => janus.createSession())
        .then((session) => this.session = session)
        .then((_) => _publish ? publishStream(session, localStream) : listenRoom(session))
        .then((pub) => this.publisher = pub)
        .then((_) => this.isSetup = true)
        .then((_) => Future.value(true));
  }

  //this is the output of this class
  List<RTCVideoView> getRemoteVideoViews() {
    return remotes.values.map((rend) => new RTCVideoView(rend)).toList();
  }

  void toggleMute() {
    isMuted = !isMuted;
    localStream.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  Future<void> setLocalStream() {
    return navigator.mediaDevices
        .getUserMedia({'audio': !isMuted, 'video': !isCameraOff})
        .then((MediaStream ms) => localStream = ms)
        .then((_) => Helper.cameras)
        .then((cameras) => {if (cameras.length > 1) supportsFlipping = true});
  }

  void flipCamera() {
    isFlipped = !isFlipped;
    if (localStream != null)
      Helper.switchCamera(localStream.getVideoTracks()[0]);
  }

  void toggleCamera() {
    //TODO: actually stop media or something, but this works for now (blacks screen)
    isCameraOff = !isCameraOff;
    localStream.getVideoTracks().forEach((track) {
      track.enabled = !isCameraOff;
    });
  }

  Future<void> toggleShareScreen() {
    if (isSharingScreen) {
      return session.videoRoomPlugin
          .destroyHandle(this.screenSharePublisher)
          .then((_) => this.screenSharePublisher = null)
          .then((_) =>
              {this.displayMediaStream.dispose(), isSharingScreen = false});
    } else {
      return navigator.mediaDevices
          .getDisplayMedia({'audio': !isMuted, 'video': !isCameraOff})
          .then((ms) => this.displayMediaStream = ms)
          .then((_) => publishStream(session, this.displayMediaStream, false, false))
          .then((pub) => this.screenSharePublisher = pub)
          .then((_) => isSharingScreen = true);
    }
  }

  void _onSessionEvent(Map map) {
    print('received session event in JVR plugin');
    print(map);
  }

  void _onWebrtcUp(Map test) {
    print('received webrtcup event in JVR plugin');
    print(test);
  }

  void _onMedia(Map test) {
    print('received media event in JVR plugin');
    print(test);
  }

  void _onHangup(Map test) {
    print('received hangup event in JVR plugin');
    print(test);
  }

  void _onSlowlink() {
    print('received slowlink event in JVR plugin');
  }

  void _onDetached(Map map) {
    print('received detatched event in JVR plugin');
    print(map);
  }

  void _onTrickle() {
    print('received trickle event in JVR plugin');
  }

  void _onVideoRoomEvent(Map event) {
    print('received videroom event in example');
    print(event);
    var data = event['plugindata']['data'];
    //if(data['sender'] != publisher.id) {
    //  print('EVENT DISCARDED BECAUSE WRONG SENDER');
    //  return;
    //}
    if (data['videoroom'] == 'event') {
      if (data['publishers'] != null) {
        createListeners(data['publishers']);
      } else if (data['unpublished'] != null) {
        removeRemote(data['unpublished']);
      }
    }
  }

  void removeRemote(int publisherId) {
    if (remotes[publisherId] != null) {
      print('Removing remote!');
      remotes.remove(publisherId);
      notifyListeners();
    }
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

  void addSubscription(int pubId, VideoRoomListener listener) {
    if (!subscriptions.containsKey(pubId)) {
      subscriptions[pubId] = listener;
      //TODO: move the listener pc stuff in here and make this method a future?
    } else {
      JanusUtil.warn('Tried to add a subscription that already exists!');
    }
  }

  void addRemote(int pubId, MediaStream mediaStream) {
    if (remotes.containsKey(pubId) ||
        (screenSharePublisher != null &&
            screenSharePublisher.publisherId == pubId)) return;
    RTCVideoRenderer newRend = new RTCVideoRenderer();
    newRend
        .initialize()
        .then((_) => {
              {newRend.srcObject = mediaStream}
            })
        .then((_) => {this.remotes[pubId] = newRend, notifyListeners()});
  }

  Future<VideoRoomPublisher> publishStream(Session session, MediaStream mediaStream,
      [bool shouldCreateListeners = true, bool shouldRegisterListeners = true]) {
    Completer<VideoRoomPublisher> completer = new Completer();
    VideoRoomPublisher pub;
    session.videoRoomPlugin
        .createPublisherHandle(room)
        .then((VideoRoomPublisher pH) => pub = pH)
        .then((_) => pub.addLocalMedia(mediaStream))
        .then((_) => pub.createAnswer())
        .then((res) => {
              if (res['publishers'] != null && shouldCreateListeners) {
                  createListeners(res['publishers'])
                }})
        .then((_) => {
          if(shouldRegisterListeners) {
            registerEvents(pub)
          }})
        .then((_) => completer.complete(pub));
    return completer.future;
  }

  Future<VideoRoomPublisher> listenRoom(Session session, [bool shouldCreateListeners = true, bool shouldRegisterListeners = true]) {
    Completer<VideoRoomPublisher> completer = new Completer();
    VideoRoomPublisher pub;
    session.videoRoomPlugin
        .createPublisherHandle(room)
        .then((VideoRoomPublisher pH) => pub = pH)
        .then((_) => pub.joinPublisher({'room':room}))
        .then((res) => {
          if (res['response'].getData()['publishers'] != null && shouldCreateListeners) {
            createListeners(res['response'].getData()['publishers'])
          }})
        .then((_) => {
          if(shouldRegisterListeners) {
            registerEvents(pub)
          }})
        .then((_) => completer.complete(pub));
    return completer.future;
  }

  void createListeners(List publishers) {
    publishers.forEach((p) {
      createListener(p);
    });
  }

  //TODO: Should this method just be createListener and respond to an event?
  //Need to register the events and make sure the code passes them all this far
  void createListener(Map publisher) {
    if (!subscriptions.containsKey(publisher['id'])) {
      //print('publisher to listen to: $publisher');
      session.videoRoomPlugin
          .listenFeed(room, publisher['id'])
          .then((listen) =>
      {
        //print('created listener handle'),
        subscriptions[publisher['id']] = listen,
        listen.pc().then((pc) =>
        {
          pc.onTrack = (track) =>
              addRemote(publisher['id'], track.streams[0]),
          listen.setRemoteAnswer()
        })
      });
    }
  }

  //TODO: Can do this with a leave command and then a seperate joinAndConfigure?
  //Saves destroying/recreating another publisher?
  Future<void> switchRoom(int room) {
    print("Switching to room: $room");
    return session.videoRoomPlugin.destroyHandle(publisher)
        .then((_) => {
          this.publisher = null,
          this.remotes.clear(),
          this.subscriptions.clear(),
          notifyListeners(),
          this.room = room
        })
        .then((_) => _publish ? publishStream(session, localStream) : listenRoom(session))
        .then((pub) => this.publisher = pub);
  }

  void close() {
    if (localStream != null) localStream.dispose();
    if (displayMediaStream != null) displayMediaStream.dispose();
    this.subscriptions.clear();
    this.remotes.clear();
  }
}
