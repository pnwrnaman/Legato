import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum AppState { idle, listening, processing, result, error }

class _HomeScreenState extends State<HomeScreen> {

  // --- 1. SETUP YOUR SERVER IP HERE ---

  // OPTION A: If using Android Emulator
  // final String apiEndpoint = "http://10.0.2.2:8000/predict_genre";

  // OPTION B: If using Real Phone (Replace with YOUR computer's IP)
  final String apiEndpoint = "http://172.20.10.8:8000/predict_genre";

  // ------------------------------------

  late final RecorderController _recorderController;
  AppState _currentState = AppState.idle;
  String _predictedGenre = "";
  double _confidence = 0.0;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    super.dispose();
  }

  // --- LOGIC 1: RECORD AUDIO ---
  Future<void> _startRecording() async {
    print("--- STARTING RECORDING ---");

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError("Microphone permission is required.");
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/temp_recording.m4a';

    try {
      await _recorderController.record(path: path);
      setState(() => _currentState = AppState.listening);

      // SAFETY NET: Auto-stop after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (_currentState == AppState.listening) {
          print("Auto-stopping recording (Time limit reached)...");
          _stopRecording();
        }
      });

    } catch (e) {
      _showError("Failed to start recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    // Prevent stopping if we aren't listening
    if (_currentState != AppState.listening) return;

    print("--- STOPPING RECORDING ---");

    try {
      final path = await _recorderController.stop();
      print("Recorder stopped. File saved at: $path");

      if (path != null) {
        _uploadAndPredict(path);
      } else {
        _showError("Recording failed (File path was null)");
      }
    } catch (e) {
      print("Error stopping recorder: $e");
      _showError("Recorder Error: $e");
    }
  }

  // --- LOGIC 2: PICK FILE (UPLOAD BUTTON) ---
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        print("File picked: ${result.files.single.path}");
        _uploadAndPredict(result.files.single.path!);
      } else {
        print("File picker canceled");
      }
    } catch (e) {
      _showError("Error picking file: $e");
    }
  }

  // --- LOGIC 3: CONNECT TO PYTHON (THE BRIDGE) ---
  Future<void> _uploadAndPredict(String filePath) async {
    setState(() => _currentState = AppState.processing);
    print("Uploading file to: $apiEndpoint");

    try {
      // 1. Create the Request
      var request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));

      // 2. Attach the Audio File
      request.files.add(await http.MultipartFile.fromPath('audio_file', filePath));

      // 3. Send to Python
      print("Sending request...");
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Response received: ${response.statusCode}");
      print("Body: $responseBody");

      // 4. Handle Result
      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _predictedGenre = data['genre'];
          // Handle confidence if it comes as int or double
          _confidence = (data['confidence'] is int)
              ? (data['confidence'] as int).toDouble()
              : data['confidence'];
          _currentState = AppState.result;
        });
      } else {
        _showError("Server Error: ${response.statusCode}\n$responseBody");
      }
    } catch (e) {
      print("Connection Error: $e");
      _showError("Connection Failed. \n\n1. Is Python running? \n2. Is the IP correct? \n3. Error: $e");
    }
  }

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
      _currentState = AppState.error;
    });
  }

  void _reset() {
    setState(() => _currentState = AppState.idle);
  }

  // --- UI CODE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Music Genre AI"), elevation: 0),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case AppState.idle:
        return Column(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Record Button
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),

              // FIX: Catch both End and Up events to prevent sticking
              onLongPressEnd: (_) => _stopRecording(),
              onLongPressUp: () => _stopRecording(),

              child: Container(
                height: 150, width: 150,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, size: 80, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Hold to Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 40),

            // 2. Upload Button
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload MP3 File"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        );

      case AppState.listening:
        return Column(
          key: const ValueKey('listening'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Listening...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width, 100),
              recorderController: _recorderController,
              waveStyle: const WaveStyle(
                waveColor: Colors.deepPurple,
                extendWaveform: true,
                showMiddleLine: false,
              ),
            ),
          ],
        );

      case AppState.processing:
        return const Column(
          key: const ValueKey('processing'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Asking AI...", style: TextStyle(fontSize: 18)),
          ],
        );

      case AppState.result:
        return Column(
          key: const ValueKey('result'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text("Genre: $_predictedGenre", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Confidence: ${(_confidence * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _reset, child: const Text("Try Again")),
          ],
        );

      case AppState.error:
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            key: const ValueKey('error'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                  "Opps!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])
              ),
              const SizedBox(height: 10),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _reset, child: const Text("Okay")),
            ],
          ),
        );
    }
  }
}