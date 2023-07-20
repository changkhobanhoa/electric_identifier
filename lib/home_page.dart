import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  Future<void>? cameraValue;
  CameraImage? cameraImage;
  bool isWorking = false;
  String result = "NO resutl";
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() async {
    super.dispose();
    _cameraController!.dispose();
    await Tflite.close();
  }

  runModeOnStreamFrames() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((plane) {
            return plane.bytes;
          }).toList(), // required
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5, // defaults to 127.5
          imageStd: 127.5, // defaults to 127.5
          rotation: 90, // defaults to 90, Android only
          numResults: 2, // defaults to 5
          threshold: 0.1, // defaults to 0.1
          asynch: true // defaults to true
          );
      result = "";
      for (var element in recognitions!) {
        result += element['label'] +
            " " +
            (element['confidence'] as double).toStringAsFixed(2) +
            "\n\n";
      }
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt");
  }

  initCamera() {
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    _cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraController!.startImageStream((image) => {
              if (!isWorking)
                {isWorking = true, cameraImage = image, runModeOnStreamFrames()}
            });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: size.width - 30,
                          height: size.height / 2 - 50,
                          child: CameraPreview(_cameraController!))),
                ),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                width: size.width - 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade300),
                margin: const EdgeInsets.only(
                  top: 35,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    result,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
