enum HTTPOperation {
  POST, GET
}

enum ConnectionState {
  connected, disconnected
}

enum ClientEvent {
  connected, disconnected, object, event, error, timeout
}

enum TransactionState { new_, started, sent, receiving, ended }

enum TransactionEvent { response, event, end, error }