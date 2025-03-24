import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AudioSaver {
  final String directory;

  AudioSaver({required this.directory});

  /// Saves a WAV file with the given [fileData]. If [name] is provided, it saves the file with that name.
  /// Otherwise, it generates a default name based on existing files in the directory.
  Future<String> saveRecording(List<int> fileData, {String? name}) async {
    try {
      // Get the application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${appDocDir.path}/$directory');

      // Create the directory if it doesn't exist
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Determine the file name
      String fileName;
      if (name != null && name.isNotEmpty) {
        fileName = name.endsWith('.wav') ? name : '$name.wav';
      } else {
        fileName = await _generateDefaultName(saveDir);
      }

      // Save the file
      final filePath = '${saveDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(fileData);

      // Save metadata (time and date)
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final metadataFile = File('${saveDir.path}/$fileName.meta');
      await metadataFile.writeAsString('Recorded on: $formattedDate');

      return filePath;
    } catch (e) {
      throw Exception('Failed to save recording: $e');
    }
  }

  /// Generates a default file name based on existing recordings in the directory.
  Future<String> _generateDefaultName(Directory saveDir) async {
    final files = saveDir.listSync();
    final recordingNumbers = <int>[];

    for (var file in files) {
      final fileName = file.path.split('/').last;
      final match = RegExp(r'Recording(\d+)\.wav').firstMatch(fileName);
      if (match != null) {
        recordingNumbers.add(int.parse(match.group(1)!));
      }
    }

    final nextNumber = (recordingNumbers.isEmpty ? 0 : recordingNumbers.reduce((a, b) => a > b ? a : b) + 1);
    return 'Recording${nextNumber.toString().padLeft(3, '0')}.wav';
  }
}
