import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

class AudioPreprocessor {
  final int sampleRate;
  final int fftSize;
  final int hopLength;

  late FFT _fft;

  AudioPreprocessor({
    required this.sampleRate,
    this.fftSize = 400,
    this.hopLength = 160,
  }) {
    _fft = FFT(fftSize);
  }

  /// Preprocess audio data for Whisper ASR.
  List<List<double>> preprocess(List<double> audio) {
    final normalizedAudio = _normalize(audio);
    final frames = _frame(normalizedAudio);
    return frames.map((frame) => _applyFFT(frame)).toList();
  }

  /// Normalize the input audio to have zero mean and unit variance.
  List<double> _normalize(List<double> audio) {
    final mean = audio.reduce((a, b) => a + b) / audio.length;
    final variance = audio
        .map((sample) => math.pow(sample - mean, 2))
        .reduce((a, b) => a + b) / audio.length;
    final stdDev = math.sqrt(variance);

    return audio.map((sample) => (sample - mean) / stdDev).toList();
  }

  /// Frame the audio data into overlapping frames.
  List<List<double>> _frame(List<double> audio) {
    final numFrames = (audio.length - fftSize + hopLength) ~/ hopLength;
    final frames = <List<double>>[];

    for (int i = 0; i < numFrames; i++) {
      final start = i * hopLength;
      final frame = audio.sublist(
        start,
        math.min(start + fftSize, audio.length),
      );

      if (frame.length < fftSize) {
        frames.add([...frame, ...List.filled(fftSize - frame.length, 0.0)]);
      } else {
        frames.add(frame);
      }
    }

    return frames;
  }

  /// Apply FFT to a single frame.
  List<double> _applyFFT(List<double> frame) {
    final inputArray = Float64List.fromList(frame);
    final fftOutput = _fft.realFft(inputArray);

    return fftOutput.map((complex) {
      final real = complex.x;
      final imaginary = complex.y;
      return math.sqrt(real * real + imaginary * imaginary);
    }).toList();
  }
}
