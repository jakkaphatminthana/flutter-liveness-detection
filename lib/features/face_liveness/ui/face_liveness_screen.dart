import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_detection/features/face_liveness/ui/widgets/face_liveness_action_text.dart';
import 'package:flutter_liveness_detection/features/face_liveness/ui/widgets/face_liveness_dashbord.dart';
import 'package:flutter_liveness_detection/features/face_liveness/ui/widgets/face_liveness_painter.dart';
import 'package:flutter_liveness_detection/features/face_liveness/utils/liveness_action_util.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceLivenessScreen extends StatefulWidget {
  final Function(bool success)? callback;

  const FaceLivenessScreen({super.key, this.callback});

  @override
  State<FaceLivenessScreen> createState() => _FaceLivenessScreenState();
}

class _FaceLivenessScreenState extends State<FaceLivenessScreen> {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true, //facial
      enableClassification: true, //probability
      minFaceSize: 0.3, //30%
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late CameraController cameraController;
  final List<LivenessAction> livenessActions = List.from(LivenessAction.values);

  // state camera
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFaceInFrame = false;

  // state actions
  bool waitingForNeutral = false;
  int currentActionIndex = 0;

  // state calculate values
  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;

  // for anroid
  Timer? detectionTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInitCamera();
    livenessActions.shuffle();
  }

  @override
  void dispose() {
    try {
      if (isCameraInitialized) {
        if (Platform.isIOS) {
          cameraController.stopImageStream();
        }
        cameraController.dispose();
      }
      faceDetector.close();
    } catch (e) {
      log("💥 Error in dispose: $e");
    }
    super.dispose();
  }

  Future<void> _checkPermissionAndInitCamera() async {
    PermissionStatus permission = await Permission.camera.status;
    log("permission = $permission");

    if (permission != PermissionStatus.granted) {
      permission = await Permission.camera.request();
      log("After request permission status = $permission");
    }

    if (permission == PermissionStatus.granted) {
      await _initializeCamera();
    } else if (permission == PermissionStatus.permanentlyDenied) {
      return _showPermissionDeniedDialog();
    } else {
      return _showPermissionDeniedDialog();
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Camera Permission Required"),
          content: const Text(
            "This feature requires access to the camera.\n\n"
            "Please enable camera permission in settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                _popScreen();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                _popScreen();
                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  // Initialize the camera controller
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize();

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        _startFaceDetection();
      }
    } catch (e) {
      log("💥 Error _initializeCamera: $e");
    }
  }

  // Start Camera Detect
  void _startFaceDetection() {
    if (!isCameraInitialized) return;

    if (Platform.isAndroid) {
      _startAndroidDetection();
    } else {
      _startIOSDetection();
    }
  }

  void _startAndroidDetection() {
    detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!mounted || isDetecting) return;

      isDetecting = true;
      try {
        await _detectFacesFromImage();
      } finally {
        isDetecting = false;
      }
    });
  }

  void _startIOSDetection() {
    cameraController.startImageStream((CameraImage image) {
      if (!isDetecting) {
        isDetecting = true;
        _detectFacesFromStream(image).then((_) {
          isDetecting = false;
        });
      }
    });
  }

  // Detect by image file (for take image)
  Future<void> _detectFacesFromImage() async {
    try {
      if (!cameraController.value.isInitialized) return;

      final XFile imageFile = await cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) {
        await _deleteTemporaryFile(imageFile.path);
        return;
      }

      await _processFaceDetectionResults(faces);
      await _deleteTemporaryFile(imageFile.path);
    } catch (e) {
      log('Error in Android face detection: $e');
    }
  }

  // Detect realtime (for stream)
  Future<void> _detectFacesFromStream(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      final bytes = allBytes.done().buffer.asUint8List();
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      if (mounted) {
        await _processFaceDetectionResults(faces);
      }
    } catch (e) {
      log("Error in iOS face detection: $e");
    }
  }

  Future<void> _processFaceDetectionResults(List<Face> faces) async {
    if (faces.isNotEmpty) {
      final face = faces.first;
      final faceInFrame = _isFaceInFrame(face);

      setState(() {
        smilingProbability = face.smilingProbability;
        leftEyeOpenProbability = face.leftEyeOpenProbability;
        rightEyeOpenProbability = face.rightEyeOpenProbability;
        headEulerAngleY = face.headEulerAngleY;
        isFaceInFrame = faceInFrame;
      });

      if (faceInFrame) {
        await _checkFaceAction(face);
      }
    } else {
      log('No faces detected');
      setState(() {
        smilingProbability = null;
        leftEyeOpenProbability = null;
        rightEyeOpenProbability = null;
        headEulerAngleY = null;
        isFaceInFrame = false;
      });
    }
  }

  Future<void> _checkFaceAction(Face face) async {
    if (waitingForNeutral) {
      if (!_isNeutralPosition(face)) return;
      setState(() => waitingForNeutral = false);
    }

    final currentAction =
        livenessActions[currentActionIndex.clamp(
          0,
          livenessActions.length - 1,
        )];

    final actionCompleted = _isActionCompleted(face, currentAction);

    if (actionCompleted) {
      final isLastStep = currentActionIndex >= livenessActions.length - 1;

      setState(() => waitingForNeutral = true);

      // Stop detection during delay
      if (Platform.isAndroid) {
        detectionTimer?.cancel();
      } else {
        if (!isLastStep) cameraController.stopImageStream();
      }

      // 3-second delay for both platforms
      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;

        setState(() => waitingForNeutral = false);

        if (isLastStep) {
          widget.callback?.call(true); //callback
          _popScreen();
        } else {
          currentActionIndex++;
          _startFaceDetection(); // Restart detection for next step
        }
      });
    }
  }

  // delete file from take image process
  Future<void> _deleteTemporaryFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      log('💥 Error deleting temp file: $e');
    }
  }

  void _popScreen() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  bool _isActionCompleted(Face face, LivenessAction action) {
    switch (action) {
      case LivenessAction.smile:
        return face.smilingProbability != null &&
            face.smilingProbability! > 0.5;
      case LivenessAction.blink:
        return (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
      case LivenessAction.lookRight:
        return face.headEulerAngleY != null && face.headEulerAngleY! < -10;
      case LivenessAction.lookLeft:
        return face.headEulerAngleY != null && face.headEulerAngleY! > 10;
      case LivenessAction.lookStraight:
        return face.headEulerAngleY != null &&
            face.headEulerAngleY! > -5 &&
            face.headEulerAngleY! < 5;
    }
  }

  // Check if the face is in a neutral position
  bool _isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  bool _isFaceInFrame(Face face) {
    final boundingBox = face.boundingBox;
    const double frameMargin = 50.0;

    return boundingBox.width > 100 &&
        boundingBox.height > 100 &&
        boundingBox.left > frameMargin &&
        boundingBox.top > frameMargin;
  }

  LivenessAction? get currentAction {
    if (!isFaceInFrame || currentActionIndex >= livenessActions.length) {
      return null;
    }
    return livenessActions[currentActionIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Liveness Detectiion",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(cameraController)),

                // Face Overlay
                CustomPaint(
                  painter: FaceLivenessPainter(
                    waitingForNeutral: waitingForNeutral,
                    isFaceInFrame: isFaceInFrame,
                  ),
                  child: Container(),
                ),

                // Text Action
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  left: 16,
                  right: 16,
                  child: FaceLivenessActionText(action: currentAction),
                ),

                Positioned(
                  bottom: 16,
                  left: 16,
                  child: FaceLivenessDashbord(
                    smilingProbability: smilingProbability,
                    leftEyeOpenProbability: leftEyeOpenProbability,
                    rightEyeOpenProbability: rightEyeOpenProbability,
                    headEulerAngleY: headEulerAngleY,
                    waitingForNeutral: waitingForNeutral,
                    isFaceInFrame: isFaceInFrame,
                    currentActionIndex: currentActionIndex,
                    livenessActionsTotal: livenessActions.length,
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
