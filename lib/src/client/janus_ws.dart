import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:web_socket_channel/io.dart';

class WSJanusClient extends JanusClient {
  IOWebSocketChannel webSocket; //null

  WSJanusClient(url): super(url);

  //@override
  //bool isClosing() => this.webSocket == null || !connected;

  @override
  Future<bool> connectJanus() async {
    if (this.webSocket == null) {
      var opts = this.handshakeTimeout != null
          ? {'handshakeTimeout': this.handshakeTimeout}
          : null;
      this.webSocket = new IOWebSocketChannel.connect(this.url,
          protocols: this.protocols, headers: opts);
      //this.webSocket.stream.listen(message, onError: error, onDone: close);
    }
  }

  // @override
  // void close() async {
  //   if (this.isClosing()) {
  //     return;
  //   }
  //   connected = false;
  //
  //   this.webSocket = null;
  // }

  @override
  Future<Session> createSession() {
    // TODO: implement createSession
    throw UnimplementedError();
  }

  @override
  bool isConnected() {
    // TODO: implement isConnected
    throw UnimplementedError();
  }

  @override
  Future<ClientResponse> request(Map<String, dynamic> request, [bool ack]) {
    // TODO: implement request
    throw UnimplementedError();
  }

  @override
  Future<void> sendObject(Map<String, dynamic> object) {
    // TODO: implement sendObject
    throw UnimplementedError();
  }

  @override
  void delegateEvent(event) {
    // TODO: implement delegateEvent
  }
}
