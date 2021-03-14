import 'package:janus_client_flutter/src/client/response.dart';
import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/plugins/handle.dart';
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
    print('error resp: ${this.response.getResponse}');
    this.code = response.getResponse['error']['code'];
    this.message  = response.getResponse['error']['reason'];
  }
}

class PluginError extends JanusError {

  int code;
  PluginHandle handle;

  PluginError({ClientResponse response, this.handle}) {
    this.message = response.getResponse['plugindata']['data']['error'];
    this.code = response.getResponse['plugindata']['data']['error_code'];
  }
}