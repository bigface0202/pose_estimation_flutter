import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

import 'camera_feed.dart';

class ImageInput extends StatefulWidget {
  final Function onSelectImage;

  ImageInput(this.onSelectImage);

  @override
  _ImageInputState createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  // File _storedImage;
  final picker = ImagePicker();
  bool loading = true;
  Map<int, dynamic> keyPoints = {};
  ui.Image image;

  Future<void> _takePicture() async {
    setState(() {
      loading = true;
    });
    final imageFile = await picker.getImage(
      source: ImageSource.camera,
    );
    if (imageFile == null) {
      return;
    }
    poseEstimation(File(imageFile.path));
  }

  Future<void> _getImageFromGallery() async {
    setState(() {
      loading = true;
    });
    final imageFile = await picker.getImage(
      source: ImageSource.gallery,
    );
    if (imageFile == null) {
      return;
    }
    poseEstimation(File(imageFile.path));
  }

  static Future loadModel() async {
    Tflite.close();
    try {
      await Tflite.loadModel(
        model: 'assets/posenet_mv1_075_float_from_checkpoints.tflite',
      );
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  Future poseEstimation(File imageFile) async {
    final imageByte = await imageFile.readAsBytes();
    image = await decodeImageFromList(imageByte);
    // Prediction
    List recognition = await Tflite.runPoseNetOnImage(
      path: imageFile.path,
      imageMean: 125.0, // defaults to 117.0
      imageStd: 125.0, // defaults to 1.0
      numResults: 2, // defaults to 5
      threshold: 0.7, // defaults to 0.1
      nmsRadius: 10,
      asynch: true,
    );
    // Extract keypoints from recognition
    if (recognition.length > 0) {
      setState(() {
        keyPoints = new Map<int, dynamic>.from(recognition[0]['keypoints']);
      });
    } else {
      keyPoints = {};
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadModel().then((val) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            loading
                ? Container(
                    width: 380,
                    height: 400,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey),
                    ),
                    child: Text(
                      'No Image Taken',
                      textAlign: TextAlign.center,
                    ),
                  )
                : FittedBox(
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.height.toDouble(),
                      child: CustomPaint(
                        painter: CirclePainter(keyPoints, image),
                      ),
                    ),
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FlatButton.icon(
                    icon: Icon(Icons.photo_camera),
                    label: Text(
                      'カメラ',
                      style: TextStyle(fontSize: 8),
                    ),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: _takePicture,
                  ),
                ),
                Expanded(
                  child: FlatButton.icon(
                    icon: Icon(Icons.photo_library),
                    label: Text(
                      'ギャラリー',
                      style: TextStyle(fontSize: 8),
                    ),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: _getImageFromGallery,
                  ),
                ),
                Expanded(
                  child: FlatButton.icon(
                    icon: Icon(Icons.photo_library),
                    label: Text(
                      'リアルタイム',
                      style: TextStyle(fontSize: 8),
                    ),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.of(context).pushNamed(CameraFeed.routeName);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Map params;
  final ui.Image image;
  CirclePainter(this.params, this.image);

  @override
  void paint(ui.Canvas canvas, Size size) {
    final paint = Paint();
    if (image != null) {
      canvas.drawImage(image, Offset(0, 0), paint);
    }
    paint.color = Colors.red;
    if (params.isNotEmpty) {
      params.forEach((index, param) {
        canvas.drawCircle(
            Offset(size.width * param['x'], size.height * param['y']),
            10,
            paint);
      });
      print("Done!");
    }
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) => false;
  // image != oldDelegate.image || params != oldDelegate.params;
}
