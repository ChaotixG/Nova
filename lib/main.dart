import 'package:flutter/material.dart';
import 'app_state.dart'; // Abstract AppState base class
import 'color_reference.dart';
import 'states/settings_state.dart';
import 'states/home_screen_state.dart'; // Home state
import 'widgets/drawer_widget.dart'; // Updated AppDrawer widget
import 'vtt/audio_recorder.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create an instance of AudioRecorder
  AudioRecorder audioRecorder = AudioRecorder();

  // Initialize the recorder
  try {
    await audioRecorder.initRecorder();
    debugPrint('Recorder initialized successfully.');
  } catch (e) {
    debugPrint('Error initializing recorder: $e');
  }

  runApp(const NovaApp());
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});

  @override
  NovaAppState createState() => NovaAppState();
}

class NovaAppState extends State<NovaApp> {
  late AppState _currentState = HomeScreenState(onStateChange: _changeState);

  /// Method to change the active state dynamically.
  void _changeState(AppState newState) {
    setState(() {
      _currentState = newState;
    });
  }

  Drawer? _getDrawer() {
    // Hide the drawer when the current state is HomeScreenState or SettingsState
    return (_currentState is HomeScreenState || _currentState is SettingsState)
        ? null
        : AppDrawer(onStateChange: _changeState); // Return the drawer if it's not either of the two states
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: AppColors.primarySwatch)
            .copyWith(secondary: AppColors.secondarySwatch),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nova'),
          centerTitle: true,
        ),
        drawer: _getDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            children: [
              if (currentChild != null) currentChild,
              ...previousChildren,
            ],
          ),
          child: _currentState,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Properly dispose of the recorder when the app is terminated
    super.dispose();
  }
}
