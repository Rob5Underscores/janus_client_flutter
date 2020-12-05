import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';

class VideoRoomListener extends VideoRoomHandle {
  int room;
  var feed;
  var offer;
  
  VideoRoomListener({id, plugin, this.room, this.feed}) :super(id, plugin);
  
  Future<void> createOffer() {
    return this.listenFeed({'room':this.room, 'feed':this.feed}).then((res) => {
      this.offer = res['jsep']['sdp']
    });
  }
  
  Future<void> setRemoteAnswer(String answer) {
    answer.replaceAll('/a=(sendrecv|sendonly)/', 'a=recvonly');
    return this.start({
      'room':this.room,
      'feed':this.feed,
      'jsep': {'type': 'answer', 'sdp':answer}
    });
  }
}