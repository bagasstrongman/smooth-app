import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_barcode_scanner/google_ml_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/data_models/continuous_scan_model.dart';
import 'package:smooth_app/main.dart';
import 'package:smooth_app/pages/scan/scan_page_helper.dart';
import 'package:smooth_ui_library/animations/smooth_reveal_animation.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MLKitScannerPage extends StatefulWidget {
  const MLKitScannerPage({Key? key}) : super(key: key);

  @override
  MLKitScannerPageState createState() => MLKitScannerPageState();
}

class MLKitScannerPageState extends State<MLKitScannerPage> {
  BarcodeScanner? barcodeScanner = GoogleMlKit.vision.barcodeScanner();
  late ContinuousScanModel _model;
  CameraController? _controller;
  int _cameraIndex = 0;
  CameraLensDirection cameraLensDirection = CameraLensDirection.back;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();

    //Find the most relevant camera to use if none of these criteria are met,
    //the default value of [_cameraIndex] will be used to select the first
    //camera in the global cameras list.
    if (cameras.any(
      (CameraDescription element) =>
          element.lensDirection == cameraLensDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((CameraDescription element) =>
            element.lensDirection == cameraLensDirection &&
            element.sensorOrientation == 90),
      );
    } else if (cameras.any((CameraDescription element) =>
        element.lensDirection == cameraLensDirection)) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (CameraDescription element) =>
              element.lensDirection == cameraLensDirection,
        ),
      );
    }

    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    _disposeLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _model = context.watch<ContinuousScanModel>();
    return Scaffold(
      body: VisibilityDetector(
        key: const Key('VisibilityDetector ML Kit'),
        onVisibilityChanged: (VisibilityInfo visibilityInfo) {
          if (visibilityInfo.visibleFraction == 0.0) {
            _stopLiveFeed();
          } else {
            _startLiveFeed();
          }
        },
        child: _liveFeedBody(),
      ),
    );
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final Size size = MediaQuery.of(context).size;
    // From: https://stackoverflow.com/questions/49946153/flutter-camera-appears-stretched/61487358#61487358:
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    double scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) {
      scale = 1 / scale;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...getScannerWidgets(
              context,
              constraints,
              _model,
            ),
            SmoothRevealAnimation(
              delay: 400,
              startOffset: Offset.zero,
              animationCurve: Curves.easeInOutBack,
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(
                    _controller!,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startLiveFeed() async {
    final CameraDescription camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.setFocusMode(FocusMode.auto);
      _controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    _controller = null;
  }

  Future<void> _disposeLiveFeed() async {
    await _controller?.dispose();
  }

  //Convert the [CameraImage] to a [InputImage]
  Future<void> _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final CameraDescription camera = cameras[_cameraIndex];
    final InputImageRotation imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatMethods.fromRawValue(
              int.parse(image.format.raw.toString()),
            ) ??
            InputImageFormat.NV21;

    final List<InputImagePlaneMetadata> planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final InputImageData inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final InputImage inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    _scanImage(inputImage);
  }

  //Checking for barcodes in the provided InputImage
  Future<void> _scanImage(InputImage inputImage) async {
    if (barcodeScanner == null || isBusy) {
      return;
    }

    isBusy = true;

    final List<Barcode> barcodes =
        await barcodeScanner!.processImage(inputImage);

    for (final Barcode barcode in barcodes) {
      _model.onScan(barcode.value.rawValue);
    }

    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}