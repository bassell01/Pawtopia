import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';



class MobileNetEmbeddingService {
  MobileNetEmbeddingService._(this._interpreter);

  final Interpreter _interpreter;

  static const int _inputSize = 224;
  static const int _embeddingSize = 1000;

  static MobileNetEmbeddingService? _instance;

  static Future<MobileNetEmbeddingService> instance() async {
    if (_instance != null) return _instance!;
    final interpreter = await Interpreter.fromAsset(
      'assets/models/MobileNet-v2.tflite',
      options: InterpreterOptions(),
    );
    _instance = MobileNetEmbeddingService._(interpreter);
    return _instance!;
  }

  Future<List<double>> embeddingFromFile(File file) async {
    final bytes = await file.readAsBytes();
    return _embeddingFromBytes(bytes);
  }

  Future<List<double>> embeddingFromUrl(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode >= 400) {
      throw Exception('Failed to download image: ${res.statusCode}');
    }
    return _embeddingFromBytes(res.bodyBytes);
  }

  List<double> _embeddingFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // input: [1,224,224,3] float32
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(_inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final p = resized.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        // MobileNet normalization: [-1, 1]
        input[0][y][x][0] = (r - 127.5) / 127.5;
        input[0][y][x][1] = (g - 127.5) / 127.5;
        input[0][y][x][2] = (b - 127.5) / 127.5;
      }
    }

    // output: [1,1280]
    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));
    _interpreter.run(input, output);

    final vec = output[0].map((e) => e.toDouble()).toList();
    return _l2Normalize(vec);
  }

  List<double> _l2Normalize(List<double> v) {
    double sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    if (sumSq == 0) return v;
    final inv = 1.0 / sqrt(sumSq);
    return v.map((x) => x * inv).toList();
  }
}
