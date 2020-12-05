import 'dart:async';

import 'package:janus_client_flutter/src/plugins/handle.dart';
import 'package:janus_client_flutter/src/plugins/plugin.dart';

// enum ParticipantType {
//   publisher, listener
// }

class VideoRoomHandle extends PluginHandle {
  VideoRoomHandle(int id, JanusPlugin plugin) : super(id: id, plugin: plugin);

  Future<Map> create([Map<String, dynamic> options]) {
    if(options == null) {
      options = {};
    }
    options['request'] = 'create';

    Completer<Map> completer = new Completer();
    this.requestMessage(options).then((res) => {
      completer.complete({'room':res.getData()['room'], 'response':res})
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<Map> destroy(Map<String, dynamic> options) {
    assert(options['room'] != null);

    options['request'] = 'destroy';
    Completer<Map> completer = new Completer();

    this.requestMessage(options).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> exists(Map<String, dynamic> options) {
    assert(options['room'] != null);

    options['request'] = 'exists';
    Completer<Map> completer = new Completer();
    this.requestMessage(options).then((res) => {
      //this had a seperate or for checking true bool or true string
      completer.complete({'exists':res.getData()['exists'], 'response': res})
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<Map> list() {
    Completer<Map> completer = new Completer();
    this.requestMessage({'request':'list'}).then((res) => {
      completer.complete({'list':res.getData()['list'] ?? [], 'response':'res'})
    }).catchError((err) => completer.completeError(err));
    return completer.future;
  }

  Future<Map> listParticipants(Map<String, dynamic> options) {
    assert(options['room'] != null);

    options['request'] = 'listparticipants';
    Completer<Map> completer = new Completer();

    this.requestMessage(options).then((res) => {
      completer.complete({
        'participants':res.getData()['participants'] ?? [],
        'response':res
      })
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> join(Map<String, dynamic> options) {
    assert(options['room'] != null);
    assert(options['ptype'] != null);

    options['request'] = 'join';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      print(res.request),
      print(res.response),
      completer.complete({
        'id':res.getData()['id'],
        'jsep':res.getJsep(),
        'response':res
      })
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> joinPublisher(Map<String, dynamic> options) {
    assert(options['room'] != null);
    options['ptype'] = 'publisher';
    //options['display'] = 'testname';
    return this.join(options);
  }

  Future<Map> joinListener(Map<String, dynamic> options) {
    assert(options['room'] != null);
    assert(options['feed'] != null);
    options['ptype'] = 'subscriber';
    return this.join(options);
  }

  Future<Map> configure(Map<String, dynamic> options) {
    if(options['audio'] == null) {
      options['audio'] = true;
    }
    if(options['video'] == null) {
      options['video'] = true;
    }
    if(options['data'] == null) {
      options['data'] = true;
    }

    options['request'] = 'configure';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> joinAndConfigure(Map<String, dynamic> options) {
    assert(options['room'] != null);
    assert(options['jsep'] != null);

    if(options['audio'] == null) {
      options['audio'] = true;
    }
    if(options['video'] == null) {
      options['video'] = true;
    }
    if(options['data'] == null) {
      options['data'] = true;
    }

    options['request'] = 'joinandconfigure';
    options['ptype'] = 'publisher';

    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({
        'id':res.getData()['id'],
        'jsep':res.getJsep(),
        'publishers': res.getData()['publishers'],
        'response':res
      })
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> publish(Map<String, dynamic> options) {
    assert(options['jsep'] != null);
    options['request'] = 'publish';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> unpublish(Map<String, dynamic> options) {
    options['request'] = 'unpublish';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> start(Map<String, dynamic> options) {
    assert(options['jsep'] != null);
    assert(options['room'] != null);

    options['request'] = 'start';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  //switch is reserved
  Future<Map> switchMount(Map<String, dynamic> options) {
    options['request'] = 'unpublish';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> add(Map<String, dynamic> options) {
    options['request'] = 'add';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> remove(Map<String, dynamic> options) {
    options['request'] = 'remove';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> leave(Map<String, dynamic> options) {
    options['request'] = 'leave';
    Completer<Map> completer = new Completer();

    this.requestMessage(options, true).then((res) => {
      completer.complete({'response':res})
    }).catchError((err) => completer.completeError(err));

    return completer.future;
  }

  Future<Map> publishFeed(Map<String, dynamic> options) {
    return this.joinAndConfigure(options);
  }
  Future<Map> listenFeed(Map<String, dynamic> options) {
    return this.joinListener(options);
  }

  //stop?
  //pause?

}