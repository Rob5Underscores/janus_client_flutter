class ClientResponse {

  Map<String, dynamic> request, response;

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
    return this.response['plugindata']['data']['error_code'] != null;
  }

  getName() {
    return this.response['plugindata']['plugin'];
  }

  getData() {
    return this.response['plugindata']['data'];
  }
}