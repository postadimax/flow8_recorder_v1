import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> with TickerProviderStateMixin {
  String _selectedFileName = "Nessun file selezionato";
  bool _isPlaying = false;
  double _playProgress = 0.0; // Da 0.0 a 1.0
  Timer? _playTimer;
  
  // Mute status per gli 8 canali
  List<bool> _isMuted = List.generate(8, (index) => false);

  // Per lo scroll sincronizzato delle onde
  late ScrollController _timelineController;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
  }

  // 1. POP-UP SELEZIONE FILE
  void _showFileSelector() async {
    final dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    List<FileSystemEntity> files = [];
    if (await dir.exists()) {
      files = dir.listSync().where((f) => f.path.endsWith('.wav')).toList();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Seleziona Sessione", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              String name = files[index].path.split('/').last;
              return ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                onTap: () {
                  setState(() {
                    _selectedFileName = name;
                    _playProgress = 0.0;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // CONTROLLI AUDIO
  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _playTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {
          _playProgress += 0.002;
          if (_playProgress >= 1.0) _stopPlay();
        });
      });
    } else {
      _playTimer?.cancel();
    }
  }

  void _stopPlay() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _playProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_selectedFileName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Color(0xFF00E5FF)),
            onPressed: _showFileSelector,
          )
        ],
      ),
      body: Stack(
        children: [
          // 2. AREA CANALI CON FORME D'ONDA
          Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildTrackRow(0, "1", "MIC 1"),
                    _buildTrackRow(1, "2", "MIC 2"),
                    _buildTrackRow(2, "3", "MIC 3"),
                    _buildTrackRow(3, "4", "MIC 4"),
                    _buildTrackRow(4, "5/6", "INST L/R"),
                    _buildTrackRow(5, "7/8", "USB L/R"),
                    _buildTrackRow(6, "M", "MONITOR"),
                    _buildTrackRow(7, "LR", "MAIN MIX"),
                  ],
                ),
              ),
              _buildTransportBar(),
            ],
          ),
          
          // 3. LINEA BIANCA VERTICALE (Playhead)
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(left: 100), // Allineata all'inizio delle onde
              child: Align(
                alignment: Alignment(lerpDouble(-1, 1, _playProgress)!, 0),
                child: Container(width: 2, color: Colors.white, height: double.infinity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(int index, String id, String label) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Sezione Mute e Info (fissa a sinistra)
          Container(
            width: 100,
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMuted[index] = !_isMuted[index]),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _isMuted[index] ? Colors.red : Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Text("M", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 10)),
                    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          
          // Sezione Forma d'onda (scorrevole)
          Expanded(
            child: Opacity(
              opacity: _isMuted[index] ? 0.2 : 1.0,
              child: Container(
                color: const Color(0xFF050505),
                child: CustomPaint(
                  painter: WaveformPainter(color: _isMuted[index] ? Colors.grey : const Color(0xFF00E5FF)),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      color: const Color(0xFF0D0D0D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.first_page, color: Colors.white), onPressed: _stopPlay),
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF00E5FF),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
            ),
          ),
          IconButton(icon: const Icon(Icons.stop, color: Colors.white), onPressed: _stopPlay),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _timelineController.dispose();
    super.dispose();
  }
}

// DISEGNO DELLA FORMA D'ONDA (SIMULATA)
class WaveformPainter extends CustomPainter {
  final Color color;
  WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2;
    // Generiamo piccoli segmenti verticali per simulare l'audio
    for (double i = 0; i < size.width; i += 4) {
      double waveHeight = (i % 30 < 15) ? 10.0 : 25.0; // Simulazione picchi
      if (i % 100 < 20) waveHeight = 2.0; // Simulazione silenzio
      
      canvas.drawLine(
        Offset(i, midY - waveHeight),
        Offset(i, midY + waveHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Funzione helper per l'animazione della linea
double? lerpDouble(num a, num b, double t) => a + (b - a) * t;
