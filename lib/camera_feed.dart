import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';

// typedef void Callback(List<dynamic> list, int h, int w);
List<CameraDescription> cameras;

class CameraFeed extends StatefulWidget {
  static const routeName = '/camera-feed';
  @override
  _CameraFeedState createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController controller;
  bool isDetecting = false;
  Map<int, dynamic> keyPoints = {};
  ui.Image image;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    availableCameras().then(
      (cameras) {
        CameraDescription rearCamera = cameras.firstWhere(
            (description) =>
                description.lensDirection == CameraLensDirection.back,
            orElse: () => null);
        if (rearCamera == null) {
          return;
        }

        controller = new CameraController(rearCamera, ResolutionPreset.high);
        controller.initialize().then(
          (_) {
            if (!mounted) {
              return;
            }
            setState(() {});
            controller.startImageStream(
              (CameraImage img) async {
                if (!isDetecting) {
                  isDetecting = true;
                  List recognition = await Tflite.runPoseNetOnFrame(
                    bytesList: img.planes.map((plane) {
                      return plane.bytes;
                    }).toList(),
                    imageHeight: img.height,
                    imageWidth: img.width,
                    numResults: 1,
                  );
                  print(recognition.length);
                  if (recognition.length > 0) {
                    // Should check mounted because setState is called after disposed
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      keyPoints = new Map<int, dynamic>.from(
                          recognition[0]['keypoints']);
                    });
                    print(keyPoints);
                  } else {
                    keyPoints = {};
                  }
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    isDetecting = false;
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
      ),
      body: OverflowBox(
        maxHeight: screenRatio > previewRatio
            ? screenH
            : screenW / previewW * previewH,
        maxWidth: screenRatio > previewRatio
            ? screenH / previewH * previewW
            : screenW,
        child: CustomPaint(
          foregroundPainter: CirclePainter(keyPoints),
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Map params;
  CirclePainter(this.params);

  @override
  void paint(ui.Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.red;
    if (params != null) {
      params.forEach((index, param) {
        canvas.drawCircle(
            Offset(size.width * param['x'], size.height * param['y']),
            5,
            paint);
      });
      print("Done!");
    }
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) => true;
  // image != oldDelegate.image || params != oldDelegate.params;
}
