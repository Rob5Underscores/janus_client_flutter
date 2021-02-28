import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/errors.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:janus_client_flutter/src/transaction.dart';

@protected
abstract class JanusClient {

  final List<String> protocols = ['janus-protocol'];
  String url, token, apiSecret;

  int connectionTimeout = 40, handshakeTimeout;
  Map<String, Transaction> transactions = {};
  Map<int, Session> sessions = {};

  var info = {};
  var configuration = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  @protected
  bool hasInfo = false, reconnect = true, connected = false;

  ClientEvent lastConnectionEvent = ClientEvent.disconnected;

  JanusClient(this.url, [debug]) {
    if(debug != null && debug) {
      JanusUtil.debugLevel = 'all';
    }
  }

  Future<Session> createSession();

  bool isConnected() => connected;

  ConnectionState getConnectionState() {
    return connected ? ConnectionState.connected : ConnectionState.disconnected;
  }

  String getVersion() {
    return (this.hasInfo) ? this.info['version_string'] : '';
  }
  
  Future<bool> connect() {
    return connectJanus();
  }

  Future<ClientResponse> getInfo() {
    Completer<ClientResponse> resp = new Completer();
    this.request({'janus':'info'}).then((res) => {
      if(res.getType() == 'server_info') {
        this.hasInfo = true,
        resp.complete(res)
      } else {
        resp.completeError(new ResponseError(response: res))
      }
    }).catchError((err) => resp.completeError(err));
    return resp.future;
  }

  Future<bool> connectJanus();

  Future<ClientResponse> request(Map<String, dynamic> request, [bool ack]);

  Future<void> sendObject(Map<String, dynamic> object);

  void deleteSession(int id) {
    this.sessions.remove(id);
    JanusUtil.log('Deleted session: $id');
    JanusUtil.log('Session count: ${this.sessions.length}');
  }

  Future<void> destroySession(int id) {
    return this.request({'janus':'destroy', 'session_id':id}).then((res) => {
      if(res.isSuccess()) {
        this.deleteSession(id)
      } else {
        throw new ResponseError(response: res)
      }
    });
  }

  Future<void> disconnect() {
    if(this.isConnected()) return this.close();
    return Future.value(null);
  }

  Future<void> close() {
    this.connected = false;
    var futures = <Future>[];
    this.sessions.values.forEach((sess) => futures.add(sess.destroy()));
    return Future.wait(futures).then((_) => "Client closed!");
  }

  void delegateEvent(event) {
    //JanusUtil.debug('Delegating event');
    JanusUtil.debug('Delegating event: $event');
    //print(this.sessions);
    int sessionId = event['session_id'] ?? null;
    if(sessionId != null && this.sessions.containsKey(sessionId)){
      //JanusUtil.debug('Event has valid session id');
      sessionId = event['session_id'];
      switch(event['janus']) {
        case 'timeout':
          this.sessions[sessionId] = null;
          break;
        default:
          this.sessions[sessionId].event(event);
          break;
      }
    } else {
      if(event['janus'] != 'keepalive') JanusUtil.log('Event delegation rejected due to no existing session');
    }
  }

}