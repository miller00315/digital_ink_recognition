import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as dir;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _language = 'en-US';
  late dir.Ink _ink;
  List<dir.StrokePoint> _points = [];
  String result = 'recognized text will be shown here';

  late DigitalInkRecognizer digitalInkRecognizer;

  DigitalInkRecognizerModelManager? digitalInkRecognizerModelManager;

  @override
  void initState() {
    super.initState();
    checkAndDownloadModel();

    _ink = dir.Ink();
  }

  bool isModelDownloaded = false;
  checkAndDownloadModel() async {
    digitalInkRecognizerModelManager ??= DigitalInkRecognizerModelManager();

    isModelDownloaded =
        await digitalInkRecognizerModelManager!.isModelDownloaded(_language);

    if (!isModelDownloaded) {
      isModelDownloaded =
          await digitalInkRecognizerModelManager!.downloadModel(_language);
    }

    if (isModelDownloaded) {
      digitalInkRecognizer = DigitalInkRecognizer(languageCode: _language);
    }

    setState(() {
      isModelDownloaded;
    });
  }

  @override
  void dispose() {
    digitalInkRecognizer.close();

    super.dispose();
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
      result = '';
    });
  }

  Future<void> _recogniseText() async {
    if (isModelDownloaded) {
      final List<RecognitionCandidate> candidates =
          await digitalInkRecognizer.recognize(_ink);

      if (candidates.isNotEmpty) {
        result = candidates.map((e) => e.text).join('\n');
      } else {
        result = 'no results';
      }
    }

    setState(() {
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Scaffold(
          backgroundColor: Colors.brown,
          body: Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 60),
                  child: const Text(
                    'Draw in the white box below',
                    style: TextStyle(color: Colors.white),
                  )),
              Container(
                margin: const EdgeInsets.only(top: 10),
                color: Colors.white,
                width: 370,
                height: 370,
                child: GestureDetector(
                  onPanStart: (DragStartDetails details) {
                    _ink.strokes.add(Stroke());
                    print("onPanStart");
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    print("onPanUpdate");
                    setState(() {
                      final RenderObject? object = context.findRenderObject();
                      final localPosition = (object as RenderBox?)
                          ?.globalToLocal(details.localPosition);
                      if (localPosition != null) {
                        _points = List.from(_points)
                          ..add(StrokePoint(
                            x: localPosition.dx,
                            y: localPosition.dy,
                            t: DateTime.now().millisecondsSinceEpoch,
                          ));
                      }
                      if (_ink.strokes.isNotEmpty) {
                        _ink.strokes.last.points = _points.toList();
                      }
                    });
                  },
                  onPanEnd: (DragEndDetails details) {
                    print("onPanEnd");
                    _points.clear();
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: Signature(ink: _ink),
                    size: Size.infinite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _recogniseText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Read Text'),
                    ),
                    ElevatedButton(
                      onPressed: _clearPad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Clear Pad'),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (result.isNotEmpty)
                Text(
                  result,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
            ],
          )),
    );
  }
}

class Signature extends CustomPainter {
  dir.Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}
