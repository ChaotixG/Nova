import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:mutex/mutex.dart';
import 'audio_processor.dart'; // Import the AudioProcessor class

class AudioRecorder {
  final Record _recorder = Record();
  final Logger _logger = Logger();
  final Mutex _mutex = Mutex();  // Use Mutex instead of Lock for thread safety
  final AudioProcessor _audioProcessor = AudioProcessor();

  bool _isRecording = false;

  /// Optional callbacks for handling audio events
  Function? onSpeechDetected;
  Function? onEOSDetected;
  Function? onAudioFrame;

  /// Initializes the recorder. Must be called before starting recording.
  Future<void> initRecorder() async {
    await _mutex.acquire();  // Acquire the mutex before performing the operation
    try {
      _logger.i('Initializing the recorder...');

      // Check if the recorder has permission
      if (!await _recorder.hasPermission()) {
        throw 'Recording permission denied';
      }

      _logger.i('Recorder initialized successfully.');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize recorder.', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }

  /// Starts recording and sets up event handlers.
  Future<void> startRecording({
    required Function onSpeechDetected,
    required Function onEOSDetected,
    Function? onAudioFrame,
  }) async {
    await _mutex.acquire();
    try {
      if (_isRecording) {
        _logger.w('Recording is already in progress.');
        return;
      }

      this.onSpeechDetected = onSpeechDetected;
      this.onEOSDetected = onEOSDetected;
      this.onAudioFrame = onAudioFrame;

      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = '${tempDir.path}/temp_audio.wav';

        _logger.i('Starting recording to $tempPath...');

        await _recorder.start(
          path: tempPath,
          encoder: AudioEncoder.wav,
          samplingRate: 16000,
          numChannels: 1,
        );

        _isRecording = true;

        _logger.i('Recording started successfully.');
      } catch (e, stackTrace) {
        _logger.e('Failed to start recording.', error: e, stackTrace: stackTrace);
        await stopRecording(); // Attempt to reset recorder state
      }
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }

  /// Stops the current recording.
  Future<void> stopRecording() async {
    await _mutex.acquire();
    try {
      if (!_isRecording) {
        _logger.w('No active recording to stop.');
        return;
      }

      try {
        _logger.i('Stopping recording...');
        await _recorder.stop();
        _isRecording = false;
        _logger.i('Recording stopped successfully.');
      } catch (e, stackTrace) {
        _logger.e('Failed to stop recording.', error: e, stackTrace: stackTrace);
      }
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }

  /// Disposes the recorder, releasing resources.
  Future<void> disposeRecorder() async {
    await _mutex.acquire();
    try {
      _logger.i('Disposing the recorder...');
      await _recorder.dispose();
      _logger.i('Recorder disposed successfully.');
    } catch (e, stackTrace) {
      _logger.e('Failed to dispose recorder.', error: e, stackTrace: stackTrace);
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }

  /// Returns the current recording status.
  Future<bool> isRecording() async {
    await _mutex.acquire();
    try {
      return _isRecording;
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }

  /// Starts voice chat mode that continuously records and checks for speech and EOS.
  Future<void> voiceChat({
    required Function onSpeechDetected,
    required Function onEOSDetected,
    Function? onAudioFrame,
  }) async {
    await _mutex.acquire();
    try {
      if (_isRecording) {
        _logger.w('Recording is already in progress.');
        return;
      }

      this.onSpeechDetected = onSpeechDetected;
      this.onEOSDetected = onEOSDetected;
      this.onAudioFrame = onAudioFrame;

      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = '${tempDir.path}/temp_audio.wav';

        _logger.i('Starting voice chat recording to $tempPath...');

        await _recorder.start(
          path: tempPath,
          encoder: AudioEncoder.wav,
          samplingRate: 16000,
          numChannels: 1,
        );

        _isRecording = true;

        // Monitor the recording progress
        Timer.periodic(Duration(milliseconds: 500), (timer) async {
          if (!_isRecording) {
            timer.cancel();  // Stop the timer if recording is stopped
            return;
          }

          // Here, we read the recorded file and analyze the audio frame
          final file = File(tempPath);
          if (await file.exists()) {
            final byteData = await file.readAsBytes();
            final audioFrame = Uint8List.fromList(byteData);
            
            // Process the audio frame using the AudioProcessor
            if (_audioProcessor.isSpeech(audioFrame)) {
              onSpeechDetected(); // Trigger speech detected callback
            }

            if (_audioProcessor.detectEOS()) {
              onEOSDetected(); // Trigger EOS detected callback
              stopRecording(); // Stop recording when EOS is detected
            }

            if (onAudioFrame != null) {
              onAudioFrame(audioFrame); // Trigger audio frame callback if provided
            }
          }
        });

        _logger.i('Voice chat recording started successfully.');
      } catch (e, stackTrace) {
        _logger.e('Failed to start voice chat recording.', error: e, stackTrace: stackTrace);
        await stopRecording(); // Attempt to reset recorder state
      }
    } finally {
      _mutex.release();  // Always release the mutex when done
    }
  }
}
