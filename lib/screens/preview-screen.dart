// @dart=2.12

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esys_flutter_share/esys_flutter_share.dart';

import 'package:tflite/tflite.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:image_classifciation_demo/components/gauge-chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreviewScreen extends StatefulWidget {
  final String imgPath;
  final String fileName;
  PreviewScreen({required this.imgPath, required this.fileName});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  File? _image;
  List? _recognitions;
  bool _busy = false;

  Future getBytes() async {
    Uint8List bytes = _image!.readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _busy = true;
    });

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String? res = await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt",
        // useGpuDelegate: true,
      );
    } on PlatformException {
      print(AppLocalizations.of(context)!.error);
    }
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future recognizeImageBinary(File? image) async {
    if (image == null) return;

    Uint8List bytes = image.readAsBytesSync();
    img.Image oriImage = img.decodeJpg(bytes);
    img.Image resizedImage = img.copyResize(oriImage, height: 224, width: 224);
    var recognitions = await Tflite.runModelOnBinary(
      binary: imageToByteListFloat32(resizedImage, 224, 127.5, 127.5),
      numResults: 6,
      threshold: 0.05,
    );

    if (mounted) {
      setState(() {
        _recognitions = recognitions;
      });
    }
  }

  GaugeChart recognitionDisplay(List recognitions) {
    List<GaugeSegment> data = recognitions
        .map((recognition) =>
            new GaugeSegment(recognition["label"], recognition["confidence"]))
        .toList();

    charts.Series<GaugeSegment, String> series =
        new charts.Series<GaugeSegment, String>(
      id: 'Segments',
      domainFn: (GaugeSegment segment, _) => segment.segment,
      measureFn: (GaugeSegment segment, _) => segment.size,
      data: data,
    );

    return GaugeChart([series], animate: false);
  }

  @override
  Widget build(BuildContext context) {
    if (this._image == null) this._image = File(widget.imgPath);

    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? Text(AppLocalizations.of(context)!.noImageSelected) : Image.file(_image!),
    ));

    if (!_busy && _recognitions == null) recognizeImageBinary(this._image);

    stackChildren.add(Center(
      child: _recognitions != null
          ? recognitionDisplay(_recognitions!)
          : Text(AppLocalizations.of(context)!.loading),
    ));

    if (_busy || _recognitions == null) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(AppLocalizations.of(context)!.previewHeader),
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  flex: 2,
                  child: Stack(
                    children: stackChildren,
                  )),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  color: Colors.black,
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        getBytes().then((bytes) {
                          Share.file(AppLocalizations.of(context)!.shareVia, widget.fileName,
                              bytes.buffer.asUint8List(), 'image/path');
                        });
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
