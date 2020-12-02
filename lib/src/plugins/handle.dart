import 'package:janus_client_flutter/src/constants.dart';
import 'package:janus_client_flutter/src/plugins/plugin.dart';

class PluginHandle {

  String id, opaqueId;
  JanusPlugin plugin;
  ConnectionState connectionState = ConnectionState.disconnected;
  bool disposed = false;

  PluginHandle({this.id, this.opaqueId, this.plugin});

  Future<void> detach() {
    return this.request({'janus':'detach'});
  }

  Future<void> hangUp() {
    if(this.connectionState == ConnectionState.connected) {
      return this.request({'janus':'hangup'});
    } else {
      return Future.error('Cant hangup, handle not connected!');
    }
  }

  Future<void> trickle(candidate) {
    return this.request({'janus':'trickle', 'candidate':candidate});
  }

  Future<void> trickles(candidates) {
    return this.request({'janus':'trickle', 'candidates':candidates});
  }

  Future<void> trickleCompleted() {
    return this.request({
      'janus': 'trickle',
      'candidate': {
        'completed': true
      }
    });
  }


  Future<void> request(Map<String,dynamic> obj) {
    obj['handle_id'] = this.id;
    return this.plugin.session.request(obj);
  }

  //event

  requestMessage(Map<String, dynamic> body) {
    var jsep;
    if(body['jsep'] != null) {
      jsep = body['jsep'];
      body.remove('jsep');
    }
    Map<String, dynamic> req = {'janus':'message','body':body};
    if(jsep != null) {
      req['jsep'] = jsep;
    }

  }

  Future<void> dispose() {
    if(!this.disposed) {
      this.disposed = true;
      return this.plugin.destroyHandle(this);
    } else {
      return Future.error('Cannot dispose handle, already disposed!');
    }
  }
}