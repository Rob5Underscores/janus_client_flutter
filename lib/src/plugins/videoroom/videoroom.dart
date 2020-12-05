import 'dart:async';

import 'package:janus_client_flutter/src/plugins/plugin.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/listener.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/publisher.dart';

const Map<String, dynamic> AudioCodec = {
  'opus': 'opus',
  'isac32': 'isac32',
  'isac16': 'isac16',
  'pcmu': 'pcmu',
  'pcma': 'pcma',
  'g722': 'g722'
};

const Map<String, dynamic> VideoCodec = {
  'vp8': 'vp8',
  'vp9': 'vp9',
  'h264': 'h264'
};

class VideoRoomPlugin extends JanusPlugin {
  
  VideoRoomHandle $defaultHandle;
  
  VideoRoomPlugin({session}):super(name:'videoroom', fullName: 'janus.plugin.videoroom', session: session);

  //TODO: Fully understand the arguments, particularly this opaqueId stuff

  Future<VideoRoomHandle> defaultHandle([String opaqueId]) {
    if($defaultHandle != null) return Future.value($defaultHandle);
    Completer<VideoRoomHandle> completer = new Completer();
    
    this.createVideoRoomHandle(opaqueId).then((handle) => {
      this.$defaultHandle = handle,
      completer.complete(handle)
    }).catchError((err) => completer.completeError(err));
    
    return completer.future;
  }
  
  Future<VideoRoomHandle> createVideoRoomHandle([String opaqueId]) {
    Completer<VideoRoomHandle> completer = new Completer();
    this.createHandle(opaqueId).then((id) => {
      this.addHandle(new VideoRoomHandle(id, this)),
      //having to cast since super method returns JanusPlugins?
      completer.complete(this.handles[id] as VideoRoomHandle)
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<VideoRoomHandle> attachVideoRoomHandle(int handleId, [String opaqueId]) {
    VideoRoomHandle vH = new VideoRoomHandle(handleId, this);
    if(opaqueId != null) vH.opaqueId = opaqueId;
    this.addHandle(vH);
    this.$defaultHandle = vH;
    return Future.value(vH);
  }

  Future<VideoRoomPublisher> createPublisherHandle(int room, [String opaqueId]) {
    VideoRoomPublisher vH;
    Completer<VideoRoomPublisher> completer = new Completer();
    this.createHandle(opaqueId).then((id) => {
      vH = new VideoRoomPublisher(id:id, plugin:this, room:room),
      if(opaqueId != null) vH.opaqueId = opaqueId,
      this.addHandle(vH),
      completer.complete(vH)
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<VideoRoomPublisher> attachPublisherHandle(String handleId, int room, [String opaqueId]) {
    VideoRoomPublisher vH = new VideoRoomPublisher(id:handleId, plugin:this, room:room);
    if(opaqueId != null) vH.opaqueId = opaqueId;
    this.addHandle(vH);
    return Future.value(vH);
  }

  Future<VideoRoomListener> createListenerHandle(int room, var feed, [String opaqueId]) {
    VideoRoomListener vL;
    Completer<VideoRoomListener> completer = new Completer();
    this.createHandle(opaqueId).then((id) => {
      vL = new VideoRoomListener(id:id,plugin: this,room: room,feed: feed),
      if(opaqueId != null) vL.opaqueId = opaqueId,
      this.addHandle(vL),
      completer.complete(vL)
    }).catchError((err)=> completer.completeError(err));

    return completer.future;
  }

  Future<VideoRoomListener> attachListenerHandle(String handleId, int room, var feed, [String opaqueId]) {
    VideoRoomListener vL = new VideoRoomListener(id:handleId,plugin:this,room:room,feed:feed);
    if(opaqueId != null) vL.opaqueId = opaqueId;
    this.addHandle(vL);
    return Future.value(vL);
  }

  Future<VideoRoomPublisher> publishFeed(int room, var offer, [String opaqueId]) {
    Completer<VideoRoomPublisher> completer = new Completer();
    this.createPublisherHandle(room, opaqueId).then((createdHandle) => {
      createdHandle.createAnswer(offer).then((_) =>
          completer.complete(createdHandle)).catchError((err) => completer.completeError(err))
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<VideoRoomListener> listenFeed(int room, var feed, [String opaqueId]) {
    Completer<VideoRoomListener> completer = new Completer();
    this.createListenerHandle(room, feed, opaqueId).then((createdHandle) => {
      createdHandle.createOffer().then((_) =>
          completer.complete(createdHandle)).catchError((err) => completer.completeError(err))
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  //returns a list of publisher ids of a given room
  Future<List> getFeeds(int room) {
    Completer<List> completer = new Completer();
    var feeds = [];
    this.defaultHandle().then((handle) =>
        handle.listParticipants({'room':room}).then((result) => {
          if(result['participants'].length > 0) {
            for(var participant in result['participant']) {
              //had string and bool true check
              if(participant['publisher'] == true) {
                feeds.add(participant['id'])
              }
            }
          },
          completer.complete(feeds)
    }).catchError((err) => completer.completeError(err))
    ).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  //list of publishers ids exlcuding given feed id
  Future<List> getFeedsExclude(int room, var feed) {
    Completer<List> completer = new Completer();
    this.getFeeds(room).then((feeds) => {
      if(feeds.contains(feed)) feeds.remove(feed),
      completer.complete(feeds)
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }


}