import 'dart:async';
import 'dart:convert';

import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/errors.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:janus_client_flutter/src/transaction.dart';

class HTTPJanusClient extends JanusClient {

  HTTPJanusClient(url) : super(url);


  @override
  Future<bool> connect() async {
    await getInfo().then((value) => {
    if(value != null) {
        this.connected = true
    }
    });

    return this.connected;
  }

  @override
  Future<Session> createSession() async{
    Map<String, dynamic> body = {
      'janus' : 'create'
    };
    Session sess;
    ClientResponse resp;
    await request(body).then((res) => {
      resp = res,
      if(resp.isSuccess()) {
        sess = new Session(id:resp.response['data']['id'], janus:this),
        JanusUtil.log('Created Session: ${sess.id}'),
      }
    });

    if(sess != null) {
      //add session
      return sess;
    }
    return Future.error('Could not create session!');
  }

  Future<ClientResponse> getInfo() async {
    Completer<ClientResponse> resp = new Completer();
    await request({'janus':'info'}).then((res) => {
      if(res.getType() == 'server_info') {
        this.hasInfo = true,
        resp.complete(res)
      } else {
        resp.completeError(new ResponseError(response: res))
      }
    });
    return resp.future;
  }
  
  @override
  void error(err) {
    // TODO: implement error
  }

  Future<void> httpCall(HTTPOperation op, {String endpoint = "", Map<String, dynamic> request}) async {
    Future<http.Response> fetching;

    Map<String, String> fetchOptions = {'cache': 'no-cache'};

    if(op == HTTPOperation.GET) {
      fetching = http.get(this.url + endpoint, headers: fetchOptions);
    } else if (op == HTTPOperation.POST) {
      String body;
      if(request != null) {
        final jsonEncoder = JsonEncoder();
        body = jsonEncoder.convert(request);
      }

      fetching = http.post(url+endpoint, headers: fetchOptions, body: body);
    }
    Map<String, dynamic> respBody;
    await fetching
        .then((resp) => {
          if(resp.statusCode == 200) {
            respBody = jsonDecode(resp.body)
          } else {
            JanusUtil.error("HTTP API Call failed ${resp.statusCode}: ${resp.body}"),
          }
        })
        .catchError((err) => JanusUtil.debug(err));
    this.dispatchObject(respBody);
    return;
  }

  @override
  Future<void> sendObject(Map<String, dynamic> req) {
    //this method is used for connecting, so we cant check if already connected
    // (for http)
    //if(this.isConnected()) {
      httpCall(HTTPOperation.POST, request: req);
      return Future.value(null);
    //} else {
    //  throw new ConnectionStateError(client: this);
    //}
  }

  Transaction createTransaction(Map<String, dynamic> request, [bool ack = false]) {
    if(this.token != null) {
      request['token'] = this.token;
    }
    if(this.apiSecret != null) {
      request['apisecret'] = this.apiSecret;
    }

    Transaction t = new Transaction(client: this, request: request);
    if(ack) {
      t.ack = ack;
    }
    this.transactions[t.id] = t;
    return t;
  }

  @override
  Future<ClientResponse> request(Map<String, dynamic> request, [bool ack = false]) async {
    Transaction t = createTransaction(request, ack);

    Completer<ClientResponse> response = new Completer();

    t.onError = (err) => response.completeError(err);
    t.onEnd = () => this.transactions[t.id] = null;
    t.onResponse = (resp) => response.complete(resp);

    t.start();

    return response.future;
  }

  dispatchObject(Map<String, dynamic> resp) {
    String transId;
    if(resp['transaction'] != null) {
      transId = resp['transaction'];
    }
    if(transId != null && transactions[transId] != null) {
      Transaction t = transactions[transId];
      ClientResponse cR = new ClientResponse(request: t.request, response: resp);
      t.response(cR);
    } else if(transId != null) {
      JanusUtil.warn('Rejected object due to no existing session',resp);
    } else {
      this.delegateEvent(resp);
    }
  }

  delegateEvent(event) {
    int sessionId;
    if(event['session_id'] != null && this.sessions[event['session_id']] != null){
      sessionId = event['session_id'];
      switch(event['janus']) {
        case 'timeout':
          this.sessions[sessionId] = null;
          break;
        default:
          //this.sessions[sessionId].event(event);
          break;
      }
    }
  }

  @override
  void close() {
    // TODO: implement close
  }
  @override
  void message(message) {
    // TODO: implement message
  }

  @override
  bool isClosing() {
    // TODO: implement isClosing
    throw UnimplementedError();
  }
  
}
