import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:janus_client_flutter/src/transaction.dart';

abstract class JanusClient {

  final List<String> protocols = ['janus-protocol'];
  String url, token, apiSecret;

  int connectionTimeout = 40, handshakeTimeout;
  Map<String, Transaction> transactions = {};
  Map<int, Session> sessions = {};

  var info = {};
  bool hasInfo = false, reconnect = true, connected = false;

  ClientEvent lastConnectionEvent = ClientEvent.disconnected;

  JanusClient(this.url);

  Future<Session> createSession();

  bool isClosing();

  bool isConnected() => connected;

  ConnectionState getConnectionState() {
    return connected ? ConnectionState.connected : ConnectionState.disconnected;
  }

  String getVersion() {
    return (this.hasInfo) ? this.info['version_string'] : '';
  }
  
  Future<void> connect();

  void close();

  void error(err);

  void message(message);

  Future<ClientResponse> request(Map<String, dynamic> request);

  Future<void> sendObject(Map<String, dynamic> object);

  Future<void> destroySession(int id) {
    return this.request({'janus':'destroy', 'session_id':id}).then((res) => {
     // if(res.isSuccess())
    });
  }

}