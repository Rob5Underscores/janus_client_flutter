import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/handle.dart';

class VideoRoomPublisher extends VideoRoomHandle {
  RTCSessionDescription desc;

  String get answer => desc.sdp;
  int room;
  int publisherId;

  VideoRoomPublisher({id, plugin, this.room}) : super(id, plugin) {
    this.pc().then((pc) => {
      pc.onTrack = (event) => JanusUtil.debug('ontrack'),
      pc.onConnectionState = (event) => JanusUtil.debug('connstate'),
      pc.onIceConnectionState = (RTCIceConnectionState connState) => {
        JanusUtil.debug('iceonnstate'),
        JanusUtil.debug(connState.toString())
      },
      pc.onRenegotiationNeeded = () => {
        JanusUtil.debug('reneg needde')
      },
      pc.onIceCandidate = (RTCIceCandidate candidate) => {
        JanusUtil.debug('ice cand'),
        this.trickle(candidate.toMap()),
      },
      pc.onSignalingState = (event) => JanusUtil.debug('signal state')
    });

  }

  Future<void> addLocalMedia(MediaStream localStream) {
    return this.pc().then((pc) => {
          pc.addTransceiver(
                  track: localStream.getAudioTracks()[0],
                  init: RTCRtpTransceiverInit(
                      direction: TransceiverDirection.SendOnly,
                      streams: [localStream]
                  ))
              .then((_) => pc.addTransceiver(
                  track: localStream.getVideoTracks()[0],
                  init: RTCRtpTransceiverInit(
                    direction: TransceiverDirection.SendOnly,
                    streams: [localStream],
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
                  )))
        });
  }

  Future<void> createAnswer([RTCSessionDescription offer]) {
    //must pass an offer (from pc.createOffer)
    RTCPeerConnection peer;
    return pc()
        .then((pc) => peer = pc)
        .then((_) => peer.createOffer({'mandatory':{'OfferToReceiveVideo': false,'OfferToReceiveAudio':false}}))
        .then((nOffer) => {
          if(offer == null) offer = nOffer,
      print('here1'),
      peer.setLocalDescription(offer).then((_) => {
          this.publishFeed({'room': this.room, 'jsep': offer.toMap()}).then((res) => {
            //print(res),
            print('done here'),
            this.publisherId = res['id'],
            this.desc = new RTCSessionDescription(
            res['jsep']['sdp'], res['jsep']['type'])
          }).then((_) => peer.setRemoteDescription(desc))
        })
    });
  }
}
