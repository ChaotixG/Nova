import 'package:tflite_flutter/tflite_flutter.dart';

class WhisperService {
  late Interpreter _interpreter;

  WhisperService() {
    _loadModel();
  }

  /// Load the TFLite model
  Future<void> _loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/whisper-tiny-en.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  /// Perform inference on the input audio data
  List<dynamic> transcribe(List<double> inputData) {
    var input = [inputData];
    var output = List.filled(1, List.filled(80, 0.0)); // Adjust based on model output
    _interpreter.run(input, output);
    return output[0];
  }
}
