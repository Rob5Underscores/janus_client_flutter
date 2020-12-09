import 'dart:async';

import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/plugins/videoroom/videoroom.dart';

enum SessionState {
  alive,
  dead,
  dying
}

class Session {

  int id;
  JanusClient janus;

  Timer keepAliveTimer;
  int keepAliveInterval = 30000,
      keepAliveFails = 2,
      keepAliveFailCount = 0;
  SessionState sessionState;

  Function onEvent;
  Function onTimeout;

  VideoRoomPlugin videoRoomPlugin;

  Session({this.id, this.janus}) {
    this.sessionState =
    this.janus.isConnected() ? SessionState.alive : SessionState.dead;
    this.startKeepAlive();
    this.videoRoomPlugin = new VideoRoomPlugin(session: this);
  }

  Future<ClientResponse> request(Map<String, dynamic> req, [bool ack]) {
    req['session_id'] = this.id;
    return this.janus.request(req, ack);
  }

  Future<int> createPluginHandle(String fullPluginName, [String opaqueId]) {
    Completer<int> completer = new Completer();
    int handleId;
    Map<String, dynamic> req = {'janus': 'attach', 'plugin': fullPluginName};
    if (opaqueId != null) {
      req['opaque_id'] = opaqueId;
    }

    this.request(req).then((clientResp) => {
      handleId = clientResp.response['data']['id'],
      if(handleId != null) {
        JanusUtil.log('Created plugin handle: $handleId'),
        completer.complete(handleId)
      } else {
        completer.completeError('Plugin handle creation failed!')
      }
    });

    return completer.future;
  }

  Future<void> keepAlive() {
    //.debug('Outgoing KeepAlive Request for Session: $id');
    return this.janus.request({
      'janus': 'keepalive', 'session_id': this.id
    });
  }

  startKeepAlive() {
    this.stopKeepAlive();
    this.keepAliveTimer =
        Timer.periodic(Duration(milliseconds: keepAliveInterval), (Timer t) =>
        {
          this.keepAlive().then((value) =>
          {
            //JanusUtil.debug('Received KeepAlive Success'),
            this.keepAliveFailCount = 0,
            this.sessionState = SessionState.alive
          }).catchError((error) =>
          {
            JanusUtil.error('keepalive-err'),
            this.keepAliveFailCount++,
            this.sessionState = SessionState.dying,
            if(this.keepAliveFailCount >= this.keepAliveFails) {
              this.sessionState = SessionState.dead,
              this.stopKeepAlive(),
              this.timeout()
            }
          })
        });
  }

  timeout() {
    this.destroy().then((_) =>
    {
      JanusUtil.debug('Destroyed session: ${this.id}'),
      if(this.onTimeout != null) this.onTimeout()
    });
  }

  Future<void> destroy() {
    this.stopKeepAlive();
    return this.janus.destroySession(this.id).catchError((err) =>
    {
      JanusUtil.debug(err),
      JanusUtil.warn('Could not destroy remote session: ${this.id}')
    });
  }

  event(event) {
    //JanusUtil.debug('Session recived event');
    if (this.videoRoomPlugin.hasHandle(event['sender'])) {
      this.videoRoomPlugin.handles[event['sender']].event(event);
    } else {
      if (this.onEvent != null) onEvent(event);
    }
  }

  stopKeepAlive() {
    this.keepAliveTimer?.cancel();
  }
}