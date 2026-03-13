import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

// Assicurati che questo file esista nella cartella lib/
import 'studio_page.dart'; 

void main() {
  runApp(const MaterialApp(
    home: Flow8Studio(),
    debugShowCheckedModeBanner: false,
  ));
}

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

  // Definizione dei 10 Canali Mono
  final List<Map<String, String>> _channelInfo = [
    {"id": "1", "name": "MIC 1"},
    {"id": "2", "name": "MIC 2"},
    {"id": "3", "name": "MIC 3"},
    {"id": "4", "name": "MIC 4"},
    {"id": "5", "name": "INST L"},
    {"id": "6", "name": "INST R"},
    {"id": "7", "name": "USB L"},
    {"id": "8", "name": "USB R"},
    {"id": "M", "name": "MONITOR"},
    {"id": "LR", "name": "MAIN MIX"},
  ];

  // Fader indipendenti per ogni canale (Gain)
  List<double> _inputGains = List.generate(10, (index) => 0.8);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    // Richiesta permessi
    await [Permission.microphone, Permission.storage].request();
    
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    
    // ATTIVAZIONE MONITORAGGIO SEMPRE ATTIVO
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      setState(() {
        _currentDb = e.decibels ?? 0.0;
      });
    });
  }

  Future<String> _getSafePath() async {
    Directory dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  void _startRecording() async {
    String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _currentFileName = "session_$timestamp.wav";
    String folderPath = await _getSafePath();

    // Registrazione multitraccia (8 canali reali dalla Flow 8)
    await _recorder!.startRecorder(
      toFile: "$folderPath/$_currentFileName",
      codec: Codec.pcm16WAV,
      numChannels: 8,
      sampleRate: 48000,
    );

    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        _mbConsumed += 0.76; // Stima per 8 canali mono
      });
    });
    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    _pulseController.stop();
    _showSaveDialog();
    setState(() {
      _isRecording = false;
      _secondsElapsed = 0;
      _mbConsumed = 0.0;
    });
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text("Registrazione Completata", style: TextStyle(color: Color(0xFF00E5FF))),
        content: Text("File salvato: $_currentFileName", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CHIUDI")),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildStatusIndicator(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _channelInfo.length,
                  itemBuilder: (context, index) => _buildChannelRow(index),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("FLOW 8 REC", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 20)),
        IconButton(
          icon: const Icon(Icons.library_music, color: Colors.white70),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudioPage())),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Text(
        _isRecording ? "REGISTRAZIONE IN CORSO..." : "MONITORAGGIO ATTIVO - PRONTO",
        style: TextStyle(color: _isRecording ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChannelRow(int index) {
    // I LED rispondono al gain impostato dallo slider
    int segmentsLit = ((_currentDb - 30) * _inputGains[index] / 3).clamp(0, 20).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 35, child: Text(_channelInfo[index]['id']!, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold))),
              Text(_channelInfo[index]['name']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const Spacer(),
              // Slider per Gain Indipendente
              SizedBox(
                width: 130,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 1, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                  child: Slider(
                    value: _inputGains[index],
                    onChanged: (v) => setState(() => _inputGains[index] = v),
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(20, (idx) => Expanded(
              child: Container(
                height: 8, margin: const EdgeInsets.symmetric(horizontal: 1),
                color: idx < segmentsLit ? (idx > 16 ? Colors.red : (idx > 13 ? Colors.orange : Colors.green)) : Colors.white10,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatTime(_secondsElapsed), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text("${_mbConsumed.toStringAsFixed(1)} MB", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red.withOpacity(0.2 + (_pulseController.value * 0.3)) : Colors.transparent,
                    border: Border.all(color: _isRecording ? Colors.red : Colors.white24, width: 3),
                  ),
                  child: Center(
                    child: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.red, size: 40),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
