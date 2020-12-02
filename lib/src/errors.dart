import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/transaction.dart';

class JanusError implements Exception{
  String message;
}

class ConnectionStateError extends JanusError {

  var client; //janusclient
  ConnectionState connectionState;

  ConnectionStateError({this.client}) {
    this.message = 'Wrong connection state';
    this.connectionState = client.getConnectionState();
  }
}

class InvalidTransactionState extends JanusError {
  TransactionState transactionState;
  Transaction transaction;

  InvalidTransactionState({this.transaction}) {
    this.message =
    'Invalid transaction state ${this.transaction.transactionState}';
    this.transactionState = this.transaction.transactionState;
  }
}

class TransactionTimeoutError extends JanusError {
  TransactionState transactionState;
  Transaction transaction;
  int timeout;

  TransactionTimeoutError({this.transaction, this.timeout}) {
    this.message = 'Transaction timeout $timeout';
    this.transactionState = this.transaction.transactionState;
  }
}

class ResponseError extends JanusError {

  int code;
  ClientResponse response;

  ResponseError({this.response}) {
    this.code = response.request['plugindata']['data']['error_code'];
    this.message  = response.request['plugindata']['data']['error'];
  }
}