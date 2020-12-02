import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/transaction.dart';

class ConnectionStateError implements Exception {

  var client; //janusclient
  String message;
  ConnectionState connectionState;

  ConnectionStateError({this.client}) {
    this.message = 'Wrong connection state';
    this.connectionState = client.getConnectionState();
  }
}

class InvalidTransactionState implements Exception {
  String message;
  TransactionState transactionState;
  Transaction transaction;

  InvalidTransactionState({this.transaction}) {
    this.message =
    'Invalid transaction state ${this.transaction.transactionState}';
    this.transactionState = this.transaction.transactionState;
  }
}

class TransactionTimeoutException implements Exception {
  String message;
  TransactionState transactionState;
  Transaction transaction;
  int timeout;

  TransactionTimeoutException({this.transaction, this.timeout}) {
    this.message = 'Transaction timeout $timeout';
    this.transactionState = this.transaction.transactionState;
  }
}