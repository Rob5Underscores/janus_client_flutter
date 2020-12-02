import 'package:janus_client_flutter/src/JanusUtil.dart';
import 'package:janus_client_flutter/src/plugins/handle.dart';
import 'package:janus_client_flutter/src/session.dart';

class JanusPlugin {
  String name, fullName;
  Session session;
  Map<String, PluginHandle> handles = new Map();

  JanusPlugin({this.name, this.fullName, this.session});

  void addHandle(PluginHandle pH) {
    handles[pH.id] = pH;
  }
  void removeHandle(String id) {
    handles.remove(id);
  }
  bool hasHandle(String id) {
    return handles.containsKey(id);
  }

  Future<String> createHandle(String opaqueId) async {
    return this.session.createPluginHandle(this.fullName, opaqueId);
  }

  Future<void> destroyHandle(PluginHandle handle) {
    return destroyHandleById(handle.id);
  }

  Future<void> destroyHandleById(String id) async {
    if(hasHandle(id)) {
      var handle = handles[id];
      await handle.detach().then((_) => {
        this.removeHandle(id),
      }).catchError((err) => JanusUtil.error(err));
    } else {
      return Future.error('Cant destroy invalid handle id');
    }
  }
}