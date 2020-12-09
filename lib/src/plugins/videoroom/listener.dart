import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';

class VideoRoomListener extends VideoRoomHandle {
  int room;
  int feed; //feed id?
  RTCSessionDescription desc;

  String get offer => desc.sdp;

  VideoRoomListener({id, plugin, this.room, this.feed}) : super(id, plugin) {
    this.pc().then((pc) => {
          pc.onTrack = (event) => JanusUtil.debug('listener: ontrack'),
          pc.onConnectionState =
              (event) => JanusUtil.debug('listener: connstate'),
          pc.onIceConnectionState = (RTCIceConnectionState connState) => {
                JanusUtil.debug('listener: iceonnstate'),
                JanusUtil.debug(connState.toString())
              },
          pc.onRenegotiationNeeded = () => {
                JanusUtil.debug('listener: reneg needde'),
                //pc.createOffer().then((offer) => pc.setLocalDescription(offer))
              },
          pc.onIceCandidate = (RTCIceCandidate candidate) => {
                JanusUtil.debug('listener: ice cand'),
                this.trickle(candidate.toMap()),
              },
          pc.onSignalingState =
              (event) => JanusUtil.debug('listener: signal state')
        });
  }

  Future<void> createOffer() {
    return this
        .listenFeed({'room': this.room, 'feed': this.feed})
        .then((res) => {
              this.desc = new RTCSessionDescription(
                  res['jsep']['sdp'], res['jsep']['type'])
            })
        .then((_) => pc())
        .then((pc) => {
              JanusUtil.debug('setting listener local'),
              //print(this.desc.toMap()),
              pc.setRemoteDescription(this.desc)
            });
  }

  Future<void> setRemoteAnswer([RTCSessionDescription answer]) {
    //answer.sdp = answer.sdp.replaceAll('/a=(sendrecv|sendonly)/', 'a=recvonly');
    JanusUtil.debug('setting listener remote');
    return this.pc().then((pc) => pc.createAnswer({
          'mandatory': {
            'OfferToReceiveVideo': true,
            'OfferToReceiveAudio': true
          }
        }).then((answer) => pc.setLocalDescription(answer).then((_) => this
                .start({
              'room': this.room,
              'feed': this.feed,
              'jsep': answer.toMap()
            }))));
  }
}
