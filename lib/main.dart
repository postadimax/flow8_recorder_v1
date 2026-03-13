import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

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
  
  // Timer e Statistiche
  Timer? _timer;
  int _secondsElapsed = 0;
  double _mbConsumed = 0.0;
  String _currentFileName = "";
  
  // Selezione Sorgente
  String _selectedSource = "FLOW 8 (USB)";
  List<String> _sources = ["FLOW 8 (USB)", "Internal Mic"];

  // Animazione Pulsante REC
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulseController.reverse();
        else if (status == AnimationStatus.dismissed) _pulseController.forward();
      });
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  void _startRecording() async {
    // Generazione nome file automatico
    String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _currentFileName = "multitracks_$timestamp.wav";

    await _recorder!.startRecorder(toFile: _currentFileName);
    
    _pulseController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        // Stima approssimativa per WAV 48kHz/24bit multitraccia
        _mbConsumed += 0.25; 
      });
    });

    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    // Reset statistiche e mostra Popup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text("Registrazione Salvata", style: TextStyle(color: Color(0xFF00E5FF))),
        content: Text("File: $_currentFileName\nPercorso: /Documents/Flow8Studio/", 
          style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );

    setState(() {
      _isRecording = false;
      _secondsElapsed = 0;
      _mbConsumed = 0.0;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- HEADER CON SELECT SORGENTE ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
                    child: const Text("F8", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedSource,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      underline: Container(),
                      items: _sources.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSource = val!),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: 24),

              // --- AUTO-GENERATED PROJECT NAME ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  _isRecording ? "RECORDING: $_currentFileName" : "READY TO RECORD",
                  style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // --- CHANNEL LIST ---
              Expanded(
                child: ListView(
                  children: [
                    _buildChannelRow(1, "MIC/LINE 1"),
                    _buildChannelRow(2, "MIC/LINE 2"),
                    _buildChannelRow(3, "MIC/LINE 3"),
                    _buildChannelRow(4, "MIC/LINE 4"),
                    _buildChannelRow(5, "INST 5"),
                    _buildChannelRow(6, "INST 6"),
                  ],
                ),
              ),

              // --- FOOTER CON TIMER E STATISTICHE ---
              Row(
                children: [
                  _buildFooterStat("TIME", _formatTime(_secondsElapsed), isBlue: true),
                  const SizedBox(width: 24),
                  _buildFooterStat("DATA", "${_mbConsumed.toStringAsFixed(1)}M"),
                  const SizedBox(width: 24),
                  _buildFooterStat("DISK", "42G"),
                  const Spacer(),
                  
                  // TASTO RECORD PULSANTE
                  GestureDetector(
                    onTap: () => _isRecording ? _stopRecording() : _startRecording(),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isRecording ? 0.5 + (_pulseController.value * 0.5) : 1.0,
                          child: Container(
                            width: 65, height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2E1515),
                              border: Border.all(color: Colors.red.withOpacity(0.5), width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle, 
                                  color: _isRecording ? Colors.red : const Color(0xFF441111)
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.circle, color: _isRecording ? Colors.red : Colors.green, size: 10),
          Text(_isRecording ? " REC" : " STANDBY", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooterStat(String label, String value, {bool isBlue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: TextStyle(color: isBlue ? const Color(0xFF00E5FF) : Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChannelRow(int id, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 35, child: Text("$id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 6),
                // LED ANIMATI (Simulati se in registrazione)
                Row(
                  children: List.generate(20, (index) {
                    bool isLit = _isRecording && index < (Random().nextInt(14) + 2);
                    return Expanded(
                      child: Container(
                        height: 12, margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isLit ? const Color(0xFF00E676) : const Color(0xFF1A1A1A),
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
}
