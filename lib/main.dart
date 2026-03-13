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
  
  // Statistiche e Timer
  Timer? _timer;
  int _secondsElapsed = 0;
  double _mbConsumed = 0.0;
  String _currentFileName = "";
  
  // Livello Audio Reale (Decibel)
  double _currentDb = 0.0;
  StreamSubscription? _recorderSubscription;

  // Sorgente
  String _selectedSource = "FLOW 8 (USB)";
  final List<String> _sources = ["FLOW 8 (USB)", "Internal Mic"];

  // Animazione Pulsante REC
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    
    // Impostiamo l'intervallo di aggiornamento per i livelli audio (es. ogni 50ms)
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
  }

  void _startRecording() async {
    String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _currentFileName = "multitracks_$timestamp.wav";

    await _recorder!.startRecorder(
      toFile: _currentFileName,
      codec: Codec.pcm16WAV, // Formato WAV per alta qualità
    );

    // Ascolto dei livelli audio in tempo reale
    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      setState(() {
        // e.decibels restituisce il livello di pressione sonora
        _currentDb = e.decibels ?? 0.0;
      });
    });

    _pulseController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        // Stima: WAV 44.1kHz 16bit stereo occupa circa 10MB al minuto (0.17MB/s)
        _mbConsumed += 0.17; 
      });
    });

    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _recorderSubscription?.cancel();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Registrazione completata", style: TextStyle(color: Color(0xFF00E5FF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("File salvato con successo:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(_currentFileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Percorso:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text("/Internal Storage/Documents/", style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF00E5FF))),
          )
        ],
      ),
    );

    setState(() {
      _isRecording = false;
      _secondsElapsed = 0;
      _mbConsumed = 0.0;
      _currentDb = 0.0;
    });
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorderSubscription?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProjectBanner(),
              const SizedBox(height: 20),
              _buildInputMonitorLabel(),
              Expanded(
                child: ListView(
                  children: List.generate(6, (index) => _buildChannelRow(index + 1)),
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
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.circle, color: _isRecording ? Colors.red : Colors.green, size: 10),
          Text(_isRecording ? " REC" : " READY", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProjectBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Text(
        _isRecording ? "FILE: $_currentFileName" : "IDLE - SELECT SOURCE AND PRESS REC",
        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildInputMonitorLabel() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("INPUT MONITORING (dB)", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChannelRow(int id) {
    // Calcoliamo quanti segmenti accendere in base ai dB reali (scala 0-120dB approx)
    // Più il suono è forte, più segmenti si accendono.
    int segmentsLit = 0;
    if (_isRecording) {
      // Normalizziamo i dB: se siamo sopra i 30dB iniziamo ad accendere i LED
      segmentsLit = ((_currentDb - 30) / 4).clamp(0, 20).toInt();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text("$id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CHANNEL INPUT", style: TextStyle(color: Colors.grey, fontSize: 8)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(20, (index) {
                    bool isLit = index < segmentsLit;
                    // I LED finali diventano rossi (clip warning)
                    Color ledColor = (index > 16) ? Colors.red : const Color(0xFF00E676);
                    return Expanded(
                      child: Container(
                        height: 14,
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
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          _buildStat("TIME", _formatTime(_secondsElapsed), isBlue: true),
          const SizedBox(width: 24),
          _buildStat("DATA", "${_mbConsumed.toStringAsFixed(1)} MB"),
          const Spacer(),
          _buildRecButton(),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isBlue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: TextStyle(color: isBlue ? const Color(0xFF00E5FF) : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildRecButton() {
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

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
