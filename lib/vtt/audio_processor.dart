import 'dart:typed_data';
import 'dart:math';
import 'package:wav/wav.dart'; // Assuming 'wav' package is being used
import 'dart:io'; // For file I/O (needed to read WAV files from disk)

class AudioProcessor {
  final int sampleRate;
  final int frameDurationMs;
  final int silenceThresholdMs;
  final double energyThreshold;

  late final int _samplesPerFrame;
  final List<double> _energyBuffer = []; // Store recent energy values

  AudioProcessor({
    this.sampleRate = 16000,
    this.frameDurationMs = 20, // Frame duration in ms (default: 20ms)
    this.silenceThresholdMs = 1500, // Silence duration threshold (default: 1.5 seconds)
    this.energyThreshold = 0.40, // Energy threshold for VAD, lowered for better detection
  }) {
    _samplesPerFrame = (sampleRate * frameDurationMs) ~/ 1000;
  }

  /// Analyze an audio frame to detect voice activity.
  bool isSpeech(Uint8List audioFrameBytes) {
    try {
      final audioFrame = _convertToFloat64List(audioFrameBytes); // Convert to Float64List
      final energy = _calculateEnergy(audioFrame);

      // Apply smoothing to the energy value
      final smoothedEnergy = _smoothEnergy(energy);

      // Early return if the smoothed energy is too low
      if (smoothedEnergy < energyThreshold) {
        print('Energy below threshold, skipping frame.');
        return false; // Frame is likely silent or has very low energy
      }

      _energyBuffer.add(smoothedEnergy);

      // Keep the buffer size manageable by limiting its length
      if (_energyBuffer.length > (silenceThresholdMs ~/ frameDurationMs)) {
        _energyBuffer.removeAt(0);
      }

      return smoothedEnergy > energyThreshold;
    } catch (e) {
      print('Error in isSpeech: $e');
      return false;
    }
  }

  /// Detect if the user has stopped talking (EOS detection).
  bool detectEOS() {
    int silenceFrames = 0;

    // Iterate through energy values in reverse to find consecutive silent frames
    for (final energy in _energyBuffer.reversed) {
      print("Energy: $energy");
      if (energy < energyThreshold) {
        silenceFrames++;
        if (silenceFrames * frameDurationMs >= silenceThresholdMs) {
          print("EOS detected: Silence for $silenceFrames frames.");
          return true; // User has stopped talking
        }
      } else {
        break; // Speech detected, reset silence frame count
      }
    }

    return false; // User is still talking or insufficient silence
  }

  /// Calculate energy of the audio frame using RMS (Root Mean Square).
  double _calculateEnergy(Float64List audioFrame) {
    try {
      // Ensure the audio frame is not empty
      if (audioFrame.isEmpty) {
        print('Warning: Audio frame is empty.');
        return 0.0; // Return 0 energy if frame is empty
      }

      // Compute the RMS energy of the audio frame
      final rms = sqrt(
        audioFrame.fold(0.0, (sum, sample) => sum + sample * sample) / audioFrame.length,
      );

      // Check if the RMS result is valid
      if (rms.isNaN || rms.isInfinite) {
        print('Warning: RMS calculation resulted in NaN or Infinity.');
        return 0.0; // Return 0 energy if calculation is invalid
      }

      return rms;
    } catch (e) {
      // Log or handle error during RMS calculation
      print('Error in _calculateEnergy: $e');
      return 0.0; // Return 0 energy in case of an error
    }
  }

  /// Smooth the energy value to avoid sudden fluctuations.
  double _smoothEnergy(double newEnergy) {
    final smoothingFactor = 0.7; // You can adjust this factor
    if (_energyBuffer.isEmpty) {
      return newEnergy;
    } else {
      final lastEnergy = _energyBuffer.last;
      return (lastEnergy * smoothingFactor) + (newEnergy * (1 - smoothingFactor));
    }
  }

  /// Decode the WAV file to raw PCM data.
  Future<List<Float64List>> decodeWavToPCM(String wavFilePath, int numChannels, WavFormat format) async {
    // Read the WAV file into a byte buffer
    final byteData = await internalReadFile(wavFilePath);

    // Decode the raw audio from the byte buffer
    final rawAudio = readRawAudio(byteData, numChannels, format);

    // Return raw audio data as List<Float64List> representing the channels
    return rawAudio;
  }

  /// Reads the raw file from the given path.
  Future<Uint8List> internalReadFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $path');
      }
      return await file.readAsBytes();
    } catch (e) {
      print('Error reading file: $e');
      rethrow;
    }
  }

  /// Reads raw audio from WAV file bytes, given the number of channels and format.
  List<Float64List> readRawAudio(Uint8List bytes, int numChannels, WavFormat format) {
    // Make sure the file size is consistent with the arguments
    final bytesPerSample = format.bytesPerSample;
    if (bytes.length % (bytesPerSample * numChannels) != 0) {
      throw Exception('Unexpected file size. File size should be a multiple of '
          '${bytesPerSample * numChannels} bytes for '
          '${format.bitsPerSample} bit $numChannels channel audio');
    }

    // Calculate the number of samples
    final numSamples = bytes.length ~/ (bytesPerSample * numChannels);

    // Initialise the channels
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(numSamples));
    }

    // Read samples.
    final byteReader = ByteData.sublistView(bytes);
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        // Read the sample for each channel and store it
        final sample = byteReader.getInt16(i * numChannels + j); // Example of reading a 16-bit sample
        channels[j][i] = sample.toDouble(); // Store the sample
      }
    }
    return channels;
  }

  /// Convert a raw Uint8List of PCM data to a Float64List (16-bit PCM as example).
  Float64List _convertToFloat64List(Uint8List byteData) {
    final Float64List audioFrame = Float64List(byteData.length ~/ 2); // 16-bit PCM data, 2 bytes per sample

    for (int i = 0; i < byteData.length; i += 2) {
      // Convert each 16-bit sample into a Float64 value (little-endian signed 16-bit PCM)
      final sample = ByteData.sublistView(byteData, i, i + 2).getInt16(0, Endian.little);
      
      // Normalize the sample to a Float64 value between -1 and 1
      // The normalization factor is 32768 for 16-bit signed PCM values
      audioFrame[i ~/ 2] = sample / 32768.0;  
    }

    return audioFrame;
  }
}
