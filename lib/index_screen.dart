import 'dart:io';

import "package:flutter/material.dart";

import "./image_input.dart";

class IndexScreen extends StatelessWidget {
  // File _pickedImage;
  File _pickedImage;

  void _selectImage(File pickedImage) {
    _pickedImage = pickedImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POSE ESTIMATION'),
      ),
      body: ImageInput(_selectImage),
    );
  }
}
