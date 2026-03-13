import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import per aprire la cartella
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
  Timer? _timer;
  int _secondsElapsed = 0;
  double _mbConsumed = 0.0;
  String _currentFileName = "";
  String _fullPath = "";
  double _currentDb = 0.0;
  StreamSubscription? _recorderSubscription;
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
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 40));
    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      setState(() => _currentDb = e.decibels ?? 0.0);
    });
  }

  Future<String> _getSafePath() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory.path;
  }

  void _startRecording() async {
    String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _currentFileName = "multitracks_$timestamp.wav";
    String folderPath = await _getSafePath();
    _fullPath = "$folderPath/$_currentFileName";

    await _recorder!.startRecorder(toFile: _fullPath, codec: Codec.pcm16WAV);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
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
    _showSaveDialog();
    setState(() {
      _isRecording = false;
      _secondsElapsed = 0;
      _mbConsumed = 0.0;
    });
  }

  // NUOVO POP-UP CON TASTO APRI CARTELLA
  void _showSaveDialog() async {
    String folderPath = await _getSafePath();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text("Sessione Salvata", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("FILE: $_currentFileName", style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("PERCORSO:", style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text(folderPath, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CHIUDI", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              final Uri uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADocuments%2FFlow8Sessions");
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                // Fallback se il link diretto non funziona
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Usa un Gestore File per aprire Documents/Flow8Sessions"))
                );
              }
            },
            icon: const Icon(Icons.folder_open, color: Colors.black, size: 18),
            label: const Text("APRI CARTELLA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorderSubscription?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // --- UI ---
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
              const SizedBox(height: 10),
              _buildProjectBanner(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildChannelRow("1", "MIC / LINE 1", canReceive: true),
                    _buildChannelRow("2", "MIC / LINE 2", canReceive: _selectedSource == "FLOW 8 (USB)"),
                    _buildChannelRow("3", "MIC / LINE 3", canReceive: _selectedSource == "FLOW 8 (USB)"),
                    _buildChannelRow("4", "MIC / LINE 4", canReceive: _selectedSource == "FLOW 8 (USB)"),
                    _buildChannelRow("5/6", "INST / LINE (L/R)", canReceive: _selectedSource == "FLOW 8 (USB)"),
                    _buildChannelRow("7/8", "USB / BT (L/R)", canReceive: _selectedSource == "FLOW 8 (USB)"),
                    _buildChannelRow("MON", "MONITOR SEND", canReceive: true),
                    _buildChannelRow("MAIN", "MAIN OUT", canReceive: true),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSource = v!),
            ),
          ),
        ),
        Icon(Icons.circle, color: _isRecording ? Colors.red : Colors.green, size: 12),
      ],
    );
  }

  Widget _buildProjectBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Text(
        _isRecording ? "REC IN CORSO..." : "PRONTO PER IL MULTITRACCIA",
        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildChannelRow(String id, String label, {required bool canReceive}) {
    int segmentsLit = 0;
    if (canReceive) {
      segmentsLit = ((_currentDb - 20) / 4.5).clamp(0, 20).toInt();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 35, child: Text(id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: canReceive ? Colors.grey : Colors.white10, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(20, (index) {
                    bool isLit = index < segmentsLit;
                    Color ledColor = (index > 16) ? Colors.red : (index > 12 ? Colors.orange : const Color(0xFF00E676));
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
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _buildStat("TIME", _formatTime(_secondsElapsed), isBlue: true),
          const SizedBox(width: 20),
          _buildStat("DATA", "${_mbConsumed.toStringAsFixed(1)} MB"),
          const Spacer(),
          GestureDetector(
            onTap: () => _isRecording ? _stopRecording() : _startRecording(),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _isRecording ? 0.5 + (_pulseController.value * 0.5) : 1.0,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E1515),
                      border: Border.all(color: Colors.red.withOpacity(0.5), width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 25, height: 25,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _isRecording ? Colors.red : const Color(0xFF551111)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isBlue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        Text(value, style: TextStyle(color: isBlue ? const Color(0xFF00E5FF) : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
