import 'dart:async';

import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/errors.dart';
import 'package:janus_client_flutter/src/plugins/plugin.dart';

const JanusEvents = ['webrtcup','media','slowlink','hangup','timeout', 'event','detached','trickle'];

class PluginHandle {

  int id;
  String opaqueId;
  JanusPlugin plugin;
  ConnectionState connectionState = ConnectionState.disconnected;
  bool disposed = false;

  Function onWebrtcUp, onMedia, onHangup, onSlowlink, onDetached, onEvent, onTrickle;

  PluginHandle({this.id, this.plugin});

  Future<void> detach() {
    return this.request({'janus':'detach'});
  }

  Future<void> hangUp() {
    if(this.connectionState == ConnectionState.connected) {
      return this.request({'janus':'hangup'});
    } else {
      return Future.error('Cant hangup, handle not connected!');
    }
  }

  Future<void> trickle(candidate) {
    return this.request({'janus':'trickle', 'candidate':candidate});
  }

  Future<void> trickles(candidates) {
    return this.request({'janus':'trickle', 'candidates':candidates});
  }

  Future<void> trickleCompleted() {
    return this.request({
      'janus': 'trickle',
      'candidate': {
        'completed': true
      }
    });
  }


  Future<ClientResponse> request(Map<String,dynamic> obj, [bool ack]) {
    obj['handle_id'] = this.id;
    return this.plugin.session.request(obj, ack);
  }

  event(Map<String,dynamic> event) {
    JanusUtil.debug('Received event to plugin handle');
    String jEvent = event['janus'];
    if(jEvent == 'webrtcup') {
      this.connectionState = ConnectionState.connected;
    } else if(jEvent== 'hangup') {
      this.connectionState = ConnectionState.disconnected;
    }
    if(JanusEvents.contains(jEvent)) {
      sendEvent(jEvent, event);
    } else {
      sendEvent('event', event);
    }
  }

  sendEvent(String eventType, Map<String,dynamic> event) {
    JanusUtil.debug('Sending handle event type: $eventType');
    switch(eventType){
      case 'webrtcup': if(onWebrtcUp != null) onWebrtcUp(event); break;
      case 'media': if(onMedia != null) onMedia(event); break;
      case 'hangup': if(onHangup != null) onHangup(event); break;
      case 'slowlink': if(onSlowlink != null) onSlowlink(event); break;
      case 'detached': if(onDetached != null) onDetached(event); break;
      case 'event': if(onEvent != null) onEvent(event); break;
      case 'trickle': if(onTrickle != null) onTrickle(event); break;
    }
  }

  Future<PluginResponse> requestMessage(Map<String, dynamic> body, [bool ack]) {
    var jsep;
    if(body['jsep'] != null) {
      jsep = body['jsep'];
      body.remove('jsep');
    }
    Map<String, dynamic> req = {'janus':'message','body':body};
    if(jsep != null) {
      req['jsep'] = jsep;
    }
    Completer<PluginResponse> completer = new Completer();
    PluginResponse pR;
    this.request(req, ack).then((res) => {
      pR = new PluginResponse(res.request, res.response),
      if(pR.isError()) {
        completer.completeError(new PluginError(response:res, handle:this))
      } else {
        completer.complete(pR)
      }
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<void> dispose() {
    if(!this.disposed) {
      this.disposed = true;
      return this.plugin.destroyHandle(this);
    } else {
      return Future.error('Cannot dispose handle, already disposed!');
    }
  }
}