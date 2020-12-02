import 'package:janus_client_flutter/src/plugins/handle.dart';
import 'package:janus_client_flutter/src/plugins/plugin.dart';

enum ParticipantType {
  publisher, listener
}

class VideoRoomHandle extends PluginHandle {
  VideoRoomHandle(String id, String opaqueId, JanusPlugin plugin) : super(id:id,opaqueId: opaqueId, plugin: plugin);


}