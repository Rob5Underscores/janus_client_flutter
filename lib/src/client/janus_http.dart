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

  int longPollRetries = 3, longPollRetryCount = 0;

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

  eventHandler(Session sess) {
    if(!this.connected) return;
    JanusUtil.debug('Long poll for session: ${sess.id} ...');
      Map<String, dynamic> request = {};
      if(this.token != null) {
        request['token'] = this.token;
      }
      if(this.apiSecret != null) {
        request['apisecret'] = this.apiSecret;
      }
      httpCall(HTTPOperation.GET, request: request, endpoint: "${sess.id}").then((_) => {
        longPollRetryCount = 0,
        eventHandler(sess)
      }).catchError((err) => {
        JanusUtil.debug("error during long poll"),
        JanusUtil.error(err),
        if(longPollRetryCount >= longPollRetries) {
          JanusUtil.error('Exceeded long poll retries. Terminating '),
          sess.timeout()
        } else {
          longPollRetryCount ++,
          new Timer(Duration(seconds:3), (() => eventHandler(sess)))
        }
      });
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
        eventHandler(sess)
      }
    });

    if(sess != null) {
      //add session
      sess.onTimeout = () => {
        JanusUtil.log('Timeout session: ${sess.id}'),
        this.deleteSession(sess.id)
      };
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
    await fetching
        .then((resp) => {
          if(resp.statusCode == 200) {
            JanusUtil.debug('http resp'),
            JanusUtil.debug(jsonDecode(resp.body)),
            this.dispatchObject(jsonDecode(resp.body))
          } else {
            JanusUtil.error("HTTP API Call failed ${resp.statusCode}: ${resp.body}"),
          }
        });
        //.catchError((err) => JanusUtil.debug(err));

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
  Future<ClientResponse> request(Map<String, dynamic> request, [bool ack]) async {
    if(ack == null) ack = false;
    Transaction t = createTransaction(request, ack);

    Completer<ClientResponse> response = new Completer();

    t.onError = (err) => response.completeError(err);
    t.onEnd = () => this.transactions[t.id] = null;
    t.onResponse = (resp) => response.complete(resp);

    t.start();

    return response.future;
  }

  dispatchObject(Map<String, dynamic> resp) {
    JanusUtil.debug('Dispatching object');
    String transId;
    //print(resp);
    if(resp['transaction'] != null) {
      transId = resp['transaction'];
    }
    if(transId != null && transactions[transId] != null) {
      Transaction t = transactions[transId];
      ClientResponse cR = new ClientResponse(request: t.request, response: resp);
      JanusUtil.debug('Object as response');
      t.response(cR);
    } else if(transId != null) {
      JanusUtil.warn('Rejected response due to no existing transaction',resp);
    } else {
      this.delegateEvent(resp);
    }
  }

  @override
  delegateEvent(event) {
    JanusUtil.debug('Delegating event');
    int sessionId;
    //JanusUtil.debug('printing event');
    //JanusUtil.debug(event);
    if(event['session_id'] != null && this.sessions[event['session_id']] != null){
      JanusUtil.debug('Event has valid session id');
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
      JanusUtil.log('Event delegation rejected due to no existing session');
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
