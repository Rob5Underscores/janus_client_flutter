import 'dart:convert';

import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/errors.dart';
import 'package:janus_client_flutter/src/session.dart';
import 'package:janus_client_flutter/src/transaction.dart';

class HTTPJanusClient extends JanusClient {

  HTTPJanusClient(url) : super(url);

  @override
  void close() {
    // TODO: implement close
  }

  @override
  Future<bool> connect() async {
    await getInfo().then((value) => {
    if(value) {
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

    await httpCall(HTTPOperation.POST, request: body).then((resp) => {
      if(resp != null) {
        JanusUtil.log('Created Session: ${resp['data']['id']}'),
        sess = new Session(id:resp['data']['id'], janus:this)
      }
    });

    if(sess != null) {
      //add session
      return sess;
    }
    return Future.error('Could not create session!');
  }

  Future<bool> getInfo() async {
    
    await httpCall(HTTPOperation.GET, endpoint: "info").then((resp) => {
      if(resp != null) {
        this.hasInfo = true
      }
    });
    return this.hasInfo;
  }
  
  @override
  void error(err) {
    // TODO: implement error
  }

  Future<Map> httpCall(HTTPOperation op, {String endpoint = "", Map<String, dynamic> request}) async {
    Future<http.Response> fetching;

    Map<String, String> fetchOptions = {
      // 'headers': 'Accept': 'application/json, text/plain, */*',
      'cache': 'no-cache'
    };

    if(op == HTTPOperation.GET) {
      fetching = http.get(this.url + endpoint, headers: fetchOptions);
    } else if (op == HTTPOperation.POST) {
      String body;
      if(request != null) {
        final jsonEncoder = JsonEncoder();
        //request['transaction'] = JanusUtil.getRandString(12);
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
        .timeout(Duration(seconds: requestTimeout), onTimeout: () => JanusUtil.error('Request timed out ${request['janus']}'))
        .catchError((err) => JanusUtil.debug(err));
    return respBody;
  }

  Future<void> sendObject(Map<String, dynamic> req) {
    if(this.isConnected()) {
      JanusUtil.debug('Sending objecting from client');
      return httpCall(HTTPOperation.POST, request: req);
    } else {
      throw new ConnectionStateError(client: this);
    }
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
    this.transactions.add(t);
    return t;
  }

  @override
  Future<void> request(Map<String, dynamic> request, [bool ack = false]) async {
    //return httpCall(HTTPOperation.POST, request:request);
    Transaction t = createTransaction(request, ack);
    await t.start();
    this.transactions.remove(t.id);
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
