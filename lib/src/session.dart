import 'dart:async';

import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';

enum SessionState {
  alive, dead, dying
}

class Session {

  int id;
  JanusClient janus;

  Timer keepAliveTimer;
  int keepAliveInterval = 30000, keepAliveFails = 2, keepAliveFailCount = 0;
  SessionState sessionState;

  Function onEvent;

  Session({this.id, this.janus}) {
    this.sessionState = this.janus.isConnected() ? SessionState.alive : SessionState.dead;
    this.startKeepAlive();
  }

  request(Map<String,dynamic> req) {
    req['session_id'] = this.id;
    return this.janus.request(req);
  }

  Future<String> createPluginHandle(String fullPluginName, [String opaqueId]) async {
    String handleId;

    Map<String,dynamic> req = {'janus':'attach', 'plugin':fullPluginName};
    if(opaqueId != null) {
      req['opaque_id'] = opaqueId;
    }

    await this.request(req)
        .then((respBody) => {
          print(respBody),
          handleId = respBody['data']['id']
    });

    if(handleId != null) {
      JanusUtil.log('Created plugin handle: $handleId');
    } else {
      return Future.error('Plugin Handle creation failed!');
    }
    
    return handleId;
  }

  Future<void> keepAlive() {
    JanusUtil.debug('Outgoing KeepAlive Request for Session: $id');
    return this.janus.request({
      'janus' : 'keepalive', 'session_id': this.id
    });
  }

  startKeepAlive() {
    this.stopKeepAlive();
    this.keepAliveTimer =
        Timer.periodic(Duration(milliseconds: keepAliveInterval), (Timer t) => {
      this.keepAlive().then((value) => {
        JanusUtil.debug('Received KeepAlive Success'),
        this.keepAliveFailCount = 0,
        this.sessionState = SessionState.alive
      }).catchError((error) => {
        JanusUtil.error('keepalive-err'),
        this.keepAliveFailCount++,
        this.sessionState = SessionState.dying,
        if(this.keepAliveFailCount >= this.keepAliveFails) {
          this.sessionState = SessionState.dead,
          this.stopKeepAlive(),
          this.destroy()
        }
      })
    });
  }

  event(event) {
    // if(this.videoRoomPlugin.hasHandle(event.sender)){
    //   this.videoRoomPlugin.getHandle(event.handle).event(event);
    // } else {
      if(this.onEvent != null) onEvent(event);
    // }
  }

  stopKeepAlive() {
    this.keepAliveTimer?.cancel();
  }


  destroy() async {
    this.stopKeepAlive();
    //this.janus.destroySession
  }
}