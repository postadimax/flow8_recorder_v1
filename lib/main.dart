import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    home: Flow8Studio(),
    debugShowCheckedModeBanner: false,
  ));
}

// --- PAGINA PRINCIPALE: REGISTRAZIONE ---
class Flow8Studio extends StatefulWidget {
  const Flow8Studio({super.key});

  @override
  State<Flow8Studio> createState() => _Flow8StudioState();
}

class _Flow8StudioState extends State<Flow8Studio> with TickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  double _mbConsumed = 0.0;
  String _currentFileName = "";
  double _currentDb = 0.0;
  StreamSubscription? _recorderSubscription;
  String _selectedSource = "FLOW 8 (USB)";
  final List<String> _sources = ["FLOW 8 (USB)", "Internal Mic"];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await [Permission.microphone, Permission.storage].request();
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 40));
    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      setState(() => _currentDb = e.decibels ?? 0.0);
    });
  }

  Future<String> _getSafePath() async {
    Directory dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  void _startRecording() async {
    String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _currentFileName = "multitracks_$timestamp.wav";
    String folderPath = await _getSafePath();
    await _recorder!.startRecorder(
      toFile: "$folderPath/$_currentFileName",
      codec: Codec.pcm16WAV,
      numChannels: 8,
      sampleRate: 48000,
    );
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { _secondsElapsed++; _mbConsumed += 0.76; });
    });
    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    _pulseController.stop();
    _showSaveDialog();
    setState(() { _isRecording = false; _secondsElapsed = 0; _mbConsumed = 0.0; });
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text("Registrato!", style: TextStyle(color: Color(0xFF00E5FF))),
        content: Text("File salvato a 8 canali:\n$_currentFileName"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (c) => const StudioPage()));
            },
            child: const Text("VAI ALLO STUDIO"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildChannelRow("1", "MIC 1", true),
                    _buildChannelRow("2", "MIC 2", _selectedSource.contains("USB")),
                    _buildChannelRow("3", "MIC 3", _selectedSource.contains("USB")),
                    _buildChannelRow("4", "MIC 4", _selectedSource.contains("USB")),
                    _buildChannelRow("5/6", "INST L/R", _selectedSource.contains("USB")),
                    _buildChannelRow("7/8", "USB L/R", _selectedSource.contains("USB")),
                    _buildChannelRow("M", "MONITOR", true),
                    _buildChannelRow("LR", "MAIN MIX", true),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text("F8", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(width: 20),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedSource,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _selectedSource = v!),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.library_music, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudioPage())),
        )
      ],
    );
  }

  Widget _buildChannelRow(String id, String label, bool active) {
    int segmentsLit = active ? ((_currentDb - 25) / 4).clamp(0, 20).toInt() : 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(id, style: TextStyle(color: active ? Colors.white : Colors.white10))),
          Expanded(
            child: Row(
              children: List.generate(20, (index) => Expanded(
                child: Container(
                  height: 12, margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: index < segmentsLit ? Colors.green : Colors.white10,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("${_mbConsumed.toStringAsFixed(1)} MB", style: const TextStyle(color: Colors.white)),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: CircleAvatar(
            radius: 30, backgroundColor: _isRecording ? Colors.red : Colors.green,
            child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
          ),
        ),
        Text(_formatTime(_secondsElapsed), style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  String _formatTime(int sec) => "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorderSubscription?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}

// --- PAGINA STUDIO ---
class StudioPage extends StatefulWidget {
  const StudioPage({super.key});
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  List<FileSystemEntity> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    if (await dir.exists()) {
      setState(() {
        _sessions = dir.listSync().where((f) => f.path.endsWith('.wav')).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("STUDIO")),
      body: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          String name = _sessions[index].path.split('/').last;
          return ListTile(
            title: Text(name, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.tune, color: Color(0xFF00E5FF)),
            onTap: () {}, // Qui andrà il mixer
          );
        },
      ),
    );
  }
}
