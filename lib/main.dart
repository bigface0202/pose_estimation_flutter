import 'package:flutter/material.dart';
import 'index_screen.dart';

import 'camera_feed.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'POSE ESTIMATION',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.black,
        ),
        home: IndexScreen(),
        routes: {
          CameraFeed.routeName: (ctx) => CameraFeed(),
        });
  }
}
