import 'package:janus_client_flutter/src/JanusUtil.dart';

class ClientResponse {

  Map<String, dynamic> request, response;

  Map<String, dynamic> get getRequest => this.request;
  Map<String, dynamic> get getResponse => this.response;

  ClientResponse({this.request, this.response});

  getType() {
    return (this.response ?? const {})['janus'] ?? null;
  }

  getJsep() {
    return (this.response ?? const {})['jsep'] ?? null;
  }

  isError() {
    return this.getType() == 'error';
  }

  isAck() {
    return this.getType() == 'ack';
  }

  isSuccess() {
    return this.getType() == 'success';
  }
}

class PluginResponse extends ClientResponse {

  PluginResponse(req, res): super(request: req, response: res);

  isError() {
    if(this.getData()['error_code'] != null) {
      return this.response['plugindata']['data']['error_code'] != null;
    }
    return false;
  }

  getName() {
    return this.response['plugindata']['plugin'];
  }

  //TODO: use null aware map operator when dart 2.12.0 comes out as stable
  getData() {
    if(this.response['plugindata'] != null && this.response['plugindata']['data'] != null) {
      return this.response['plugindata']['data'];
    }
    JanusUtil.debug("Trying to get null data");
    return {};
  }
}