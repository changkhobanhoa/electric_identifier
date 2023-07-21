import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:translator/translator.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? controller;
  Future<void>? cameraValue;
  CameraImage? cameraImage;
  bool isWorking = false;
  String result = "NO resutl";
  GoogleTranslator translator = GoogleTranslator();
  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  String translate(String txt) {
    String a = "";
    translator
        .translate(
      txt,
      to: 'vi',
    )
        .then((value) {
      setState(() {
        a = value as String;
      });
    });
    return a;
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt");
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
        result += element['label'] + " " + translate(element['label']) + "\n";
      }
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  initCamera() {
    controller = CameraController(cameras[0], ResolutionPreset.high);
    controller!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller!.startImageStream((image) => {
              if (!isWorking)
                {isWorking = true, cameraImage = image, runModeOnStreamFrames()}
            });
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller!.dispose();
    await Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: Transform.scale(
                  scale: 1.0,
                  child: AspectRatio(
                    aspectRatio: 3.0 / 4.0,
                    child: OverflowBox(
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          height: size.height / 2,
                          child: Stack(
                            children: [
                              CameraPreview(controller!),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade300),
                height: 200,
                margin: const EdgeInsets.only(
                  top: 35,
                ),
                width: double.infinity,
                child: SingleChildScrollView(
                    child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                  ),
                  textAlign: TextAlign.left,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
