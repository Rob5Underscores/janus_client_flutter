import 'package:janus_client_flutter/janus_client_flutter.dart';
import 'package:janus_client_flutter/src/constants.dart';

class Transaction {
  int id, timeout = 12000;

  JanusClient client;

  Map<String, dynamic> request;

  TransactionState transactionState = TransactionState.new_;

  bool ackReceived = false, responseReceived = false, lateAck = false, ack = false;

  Transaction({this.request, this.client}) {
    //set timeout seperately if not provided
    this.id = createId();
    this.request['transaction'] = this.id;
  }

  start() {
    if(this.transactionState == TransactionState.new_) {
      this.transactionState = TransactionState.started;
      //this.startTimeout();
      //this.client.se
    }
  }

  int createId() {}


}
