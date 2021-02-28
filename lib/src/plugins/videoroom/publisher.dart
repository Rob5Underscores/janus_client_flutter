import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';

class VideoRoomPublisher extends VideoRoomHandle {
  RTCSessionDescription desc;

  String get answer => desc.sdp;
  int room;
  int publisherId;

  VideoRoomPublisher({id, plugin, this.room}) : super(id, plugin) {
    _setPCListeners();
  }

  Future<void> _setPCListeners() {
    return this.pc().then((pc) => {
      pc.onTrack = (event) => JanusUtil.debug('ontrack'),
      pc.onConnectionState = (event) => JanusUtil.debug('connstate'),
      pc.onIceConnectionState = (RTCIceConnectionState connState) => {
        JanusUtil.debug('iceonnstate'),
        JanusUtil.debug(connState.toString())
      },
      pc.onRenegotiationNeeded = () => {
        JanusUtil.debug('reneg needde')
      },
      pc.onIceCandidate = (candidate) => {
        JanusUtil.debug('ice cand'),
        this.trickle(candidate.toMap()),
      },
      pc.onSignalingState = (event) => JanusUtil.debug('signal state'),
      pc.onIceGatheringState = (ev) => JanusUtil.debug('ice gather state'),
    });
  }

  Future<void> addLocalMedia(MediaStream localStream) {
    return this.pc().then((pc) => {
          localStream.getTracks().forEach((track) async =>
          await pc.addTransceiver(
                  track: track,
                  init: RTCRtpTransceiverInit(
                      direction: TransceiverDirection.SendOnly,
                      streams: [localStream]
                  ))
          )});
  }

  Future<Map> createAnswer([RTCSessionDescription offer]) {
    //must pass an offer (from pc.createOffer)
    RTCPeerConnection peer;
    Map result;
    Completer<Map> completer = new Completer();
    pc().then((pc) => peer = pc)
        .then((_) => peer.createOffer({'offerToReceiveVideo': false, 'offerToReceiveAudio':false}))
        .then((nOffer) => {
          if(offer == null) offer = nOffer,
      peer.setLocalDescription(offer).then((_) => {
          this.publishFeed({'room': this.room, 'jsep': offer.toMap()}).then((res) => {
            //print('publish res: $res'),
            //print('publisher here 2'),
            this.publisherId = res['id'],
            this.desc = new RTCSessionDescription(
            res['jsep']['sdp'], res['jsep']['type']),
            result = res
          }).then((_) => peer.setRemoteDescription(desc))
              .then((_) => completer.complete(result))
        })
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }
}
