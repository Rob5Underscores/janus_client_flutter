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

  HTTPJanusClient(url, [debug = false]) : super(url,debug);

  @override
  Future<bool> connectJanus() {
    Completer<bool> completer = new Completer();
    getInfo().then((clientResponse) => {
      this.connected = true,
      completer.complete(this.connected)
    }).catchError((err) => completer.completeError(err));

    return completer.future;
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
        if(this.connected) {
          //incase client has disconnected during long poll
          longPollRetryCount = 0,
          eventHandler(sess)
        }
      }).catchError((err) => {
        JanusUtil.debug("Error during long poll"),
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
    Completer<Session> completer = new Completer();
    Session sess;
    ClientResponse resp;
    this.request({'janus' : 'create'}).then((res) => {
      resp = res,
      if(resp.isSuccess()) {
        sess = new Session(id:resp.response['data']['id'], janus:this),
        this.sessions[sess.id] = sess,
        sess.onTimeout = () => {
          JanusUtil.log('Timeout session: ${sess.id}'),
          this.deleteSession(sess.id)
        },
        JanusUtil.log('Created Session: ${sess.id}'),
        eventHandler(sess),
        completer.complete(sess)
      }
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }


  Future<void> httpCall(HTTPOperation op, {String endpoint = "", Map<String, dynamic> request}) {
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
      //JanusUtil.debug("Body: $body");
      fetching = http.post(url+endpoint, headers: fetchOptions, body: body);
    }

    return fetching
        .then((resp) => {
          if(resp.statusCode == 200) {
            this.dispatchObject(jsonDecode(resp.body))
          } else {
            JanusUtil.error("HTTP API Call failed ${resp.statusCode}: ${resp.body}"),
            throw new ResponseError(response: jsonDecode(resp.body))
          }
        });
  }

  @override
  Future<void> sendObject(Map<String, dynamic> req) {
    //this method is used for connecting, so we cant check if already connected
    // (for http)
    //if(this.isConnected()) {
      return httpCall(HTTPOperation.POST, request: req);
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
  Future<ClientResponse> request(Map<String, dynamic> request, [bool ack]) {
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
    //JanusUtil.debug('Dispatching object');
    String transId;
    //print(resp);
    if(resp['transaction'] != null) {
      transId = resp['transaction'];
    }
    if(transId != null && transactions[transId] != null) {
      Transaction t = transactions[transId];
      ClientResponse cR = new ClientResponse(request: t.request, response: resp);
      //JanusUtil.debug('Object as response');
      t.response(cR);
    } else if(transId != null) {
      JanusUtil.warn('Rejected response due to no existing transaction',resp);
    } else {
      this.delegateEvent(resp);
    }
  }
}
