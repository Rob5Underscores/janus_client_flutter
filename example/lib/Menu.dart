import 'package:flutter/material.dart';
import 'package:janus_client_flutter_example/widgets/NewVideoRoomExample.dart';

class Menu extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Janus Client'),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text("VideoRoom Example"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return NewVideoRoomExample(key: UniqueKey());
                }));
              },
            )
          ],
        ));
  }
}
