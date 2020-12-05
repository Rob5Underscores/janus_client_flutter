import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';

class VideoRoomPublisher extends VideoRoomHandle {
  var answer;
  int room;
  int publisherId;

  VideoRoomPublisher({id, plugin, this.room}): super(id, plugin);

  Future<void> createAnswer(RTCSessionDescription offer) {
    //must pass an offer (from pc.createOffer)
    return this.publishFeed({'room':this.room, 'jsep':offer.toMap()}).then((res) => {
      this.publisherId = res['id'],
      this.answer = res['jsep']['sdp']
    });
  }
}