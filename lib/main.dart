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

class Flow8Studio extends StatefulWidget {
  const Flow8Studio({super.key});

  @override
  State<Flow8Studio> createState() => _Flow8StudioState();
}

class _Flow8StudioState extends State<Flow8Studio> with TickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  
  // Statistiche
  Timer? _timer;
  int _secondsElapsed = 0;
  double _mbConsumed = 0.0;
  String _currentFileName = "";
  
  // Livelli Audio
  double _currentDb = 0.0;
  StreamSubscription? _recorderSubscription;

  // Sorgente
  String _selectedSource = "FLOW 8 (USB)";
  final List<String> _sources = ["FLOW 8 (USB)", "Internal Mic"];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await [Permission.microphone, Permission.storage].request();

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    
    // Monitoraggio attivo subito (anche se non registra)
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 40));
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
    _currentFileName = "multitracks_$timestamp.wav";
    String folderPath = await _getSafePath();

    // REGISTRAZIONE 8 CANALI REALE
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
        // 8 canali a 16bit/48kHz occupano circa 0.768 MB al secondo
        _mbConsumed += 0.76; 
      });
    });

    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Sessione Salvata", style: TextStyle(color: Color(0xFF00E5FF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("File: $_currentFileName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Cartella: Documents/Flow8Sessions", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("OK", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              Navigator.pop(context);
              // Qui andrai alla pagina studio (da creare)
            }, 
            child: const Text("APRI STUDIO", style: TextStyle(color: Colors.black))
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 15),
              _buildSessionInfo(),
              const SizedBox(height: 15),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
          child: const Text("F8", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSource,
              dropdownColor: const Color(0xFF111111),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSource = v!),
            ),
          ),
        ),
        _buildLibraryButton(),
      ],
    );
  }

  Widget _buildLibraryButton() {
    return IconButton(
      icon: const Icon(Icons.library_music, color: Colors.white54),
      onPressed: () { /* Navigazione futura alla lista file */ },
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        _isRecording ? "RECORDING: $_currentFileName" : "ENGINE READY - 8 CHANNELS ENABLED",
        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildChannelRow(String id, String label, bool active) {
    int segmentsLit = 0;
    if (active) {
      // Sensibilità LED: regola qui per rendere i LED più o meno reattivi
      segmentsLit = ((_currentDb - 25) / 4).clamp(0, 20).toInt();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 35, child: Text(id, style: TextStyle(color: active ? Colors.white : Colors.white10, fontWeight: FontWeight.bold))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: active ? Colors.grey : Colors.white10, fontSize: 8)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(20, (index) {
                    bool isLit = index < segmentsLit;
                    Color ledColor = (index > 16) ? Colors.red : (index > 13 ? Colors.orange : const Color(0xFF00E676));
                    return Expanded(
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isLit ? ledColor : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: [
          _buildStat("ELAPSED TIME", _formatTime(_secondsElapsed), isBlue: true),
          const SizedBox(width: 30),
          _buildStat("STORAGE USE", "${_mbConsumed.toStringAsFixed(1)} MB"),
          const Spacer(),
          _buildRecordButton(),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isBlue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        Text(value, style: TextStyle(color: isBlue ? const Color(0xFF00E5FF) : Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: () => _isRecording ? _stopRecording() : _startRecording(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: _isRecording ? 0.4 + (_pulseController.value * 0.6) : 1.0,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E1515),
                border: Border.all(color: Colors.red.withOpacity(0.5), width: 4),
              ),
              child: Center(
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: _isRecording ? Colors.red : const Color(0xFF551111)
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  String _formatTime(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorderSubscription?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
