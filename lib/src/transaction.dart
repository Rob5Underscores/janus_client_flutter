import 'dart:async';

import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/errors.dart';

class Transaction {
  String id;
  int timeout = 12000;

  JanusClient client;

  Map<String, dynamic> request;

  TransactionState transactionState = TransactionState.new_;

  Timer timer;

  bool ackReceived = false, responseReceived = false, lateAck = false, ack = false;

  //takes resp (Map)
  Function onResponse;
  //takes ack resp (Map)
  Function onAck;
  //takes Exception
  Function onError;
  Function onEnd;
  //takes Map of request
  Function onSent;

  Transaction({this.request, this.client}) {
    //set timeout seperately if not provided
    this.id = JanusUtil.getRandString(12);
    this.request['transaction'] = this.id;
  }

  Future<void> start() {
    if(this.transactionState == TransactionState.new_) {
      this.transactionState = TransactionState.started;
      this.startTimeout();
      //http sent event will actually come back after resp?
      return this.client.sendObject(this.request)
          .then((_) => {if(onSent != null) onSent(this.request)})
          .catchError((err) => {
            stopTimeout(),
            onError(err)}
          );
    } else {
      onError(new InvalidTransactionState(transaction: this));
    }
  }

  response(ClientResponse response) {
    if(this.transactionState == TransactionState.started || this.transactionState == TransactionState.receiving) {
      this.transactionState = TransactionState.receiving;
      if(response.isError()) {
        this.stopTimeout();
        //print('resp err: ${response.response}');
        onError(new ResponseError(response: response));
      } else if(this.ack == true && response.isAck()) {
        this.ackReceived = true;
        if(onAck != null) onAck(response);
        if(this.responseReceived == true) {
          this.lateAck = true;
          this.end();
        } else {
          this.startTimeout();
        }
      } else {
        //response?
        this.responseReceived = true;
        onResponse(response);
        if(this.ack && !this.ackReceived) {
          this.startTimeout();
        } else {
          this.end();
        }
      }
    } else {
      this.stopTimeout();
      onError(new InvalidTransactionState(transaction: this));
    }
  }

  end() {
    this.stopTimeout();
    if(this.transactionState != TransactionState.ended) {
      this.transactionState = TransactionState.ended;
      if(this.onEnd != null) this.onEnd();
    }
  }

  startTimeout() {
    this.stopTimeout();
    this.timer = Timer(new Duration(milliseconds: timeout), () => {
      onError(new TransactionTimeoutError(transaction: this, timeout:this.timeout))
    });
  }

  stopTimeout() {
    this.timer?.cancel();
  }



}
