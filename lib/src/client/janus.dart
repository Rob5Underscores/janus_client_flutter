import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:janus_client_flutter/src/transaction.dart';

abstract class JanusClient {

  final List<String> protocols = ['janus-protocol'];
  String url, token, apiSecret;

  int requestTimeout = 60, connectionTimeout = 40, handshakeTimeout;
  List<Transaction> transactions = [];
  List<Session> sessions = [];

  var info = {}, connectionTimeoutTimer; //null
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
  
  Future<bool> connect();

  void close();

  void error(err);

  void message(message);

  Future<void>request(Map<String, dynamic> request);

}