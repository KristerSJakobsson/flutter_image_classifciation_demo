// @dart=2.12

import 'package:image_classifciation_demo/screens/preview-screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;

  const _MediaSizeClipper(this.mediaSize);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? cameraController;
  List? cameras;
  int? selectedCameraIndex;
  String? imgPath;

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      // Dispose of existing camera
      await cameraController!.dispose();
    }

    cameraController = CameraController(cameraDescription,
        ResolutionPreset.high,
        enableAudio: false);

    cameraController!.addListener(() {
      // Once mounted, reset the state
      if (mounted) {
        setState(() {});
      }
    });

    // Initialize new camera
    await cameraController!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  /// Display camera preview
  Widget cameraPreview() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Text(
        AppLocalizations.of(context)!.loading,
        style: TextStyle(
            color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      );
    }

    final mediaSize = MediaQuery.of(context).size;
    final scale;
    // Aspect ratio here is Width / Height, mediaSize will rotate with the device but the cameraController remains the same
    // Thus, in order to keep display correct both when rotating and not we need to have separate logic for scale
    if(mediaSize.width > mediaSize.height) {
      scale = mediaSize.aspectRatio / cameraController!.value.aspectRatio;
    }
    else {
      scale = 1 / (cameraController!.value.aspectRatio * mediaSize.aspectRatio);
    }
    return ClipRect(
      clipper: _MediaSizeClipper(mediaSize),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: CameraPreview(cameraController!),
      ),
    );   //
  }

  Widget cameraControl(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Icons.camera,
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                onCapture(context);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget cameraToggle() {
    if (cameras == null || cameras!.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras![selectedCameraIndex!];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
            onPressed: () {
              onSwitchCamera();
            },
            icon: Icon(
              getCameraLensIcons(lensDirection),
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              getCameraLensLabel(lensDirection),
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            )),
      ),
    );
  }

  onCapture(context) async {
    await cameraController!.takePicture().then((value) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PreviewScreen(
                    imgPath: value.path,
                    fileName: value.name,
                  )
          )
      );
    });
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((value) {
      this.cameras = value;
      if (cameras != null && cameras!.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras![selectedCameraIndex!]).then((value) {});
      } else {
        print(AppLocalizations.of(context)!.noCamera);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: cameraPreview(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                width: double.infinity,
                padding: EdgeInsets.all(15),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    cameraToggle(),
                    cameraControl(context),
                    Spacer(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  getCameraLensIcons(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return CupertinoIcons.photo_camera;
    }
  }

  getCameraLensLabel(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return AppLocalizations.of(context)!.backCamera;
      case CameraLensDirection.front:
        return AppLocalizations.of(context)!.frontCamera;
      case CameraLensDirection.external:
        return AppLocalizations.of(context)!.externalCamera;
      default:
        return AppLocalizations.of(context)!.unknownCamera;
    }
  }

  onSwitchCamera() {
    selectedCameraIndex = selectedCameraIndex != null &&
            selectedCameraIndex! < cameras!.length - 1
        ? selectedCameraIndex! + 1
        : 0;
    CameraDescription selectedCamera = cameras![selectedCameraIndex!];
    initCamera(selectedCamera);
  }
}
