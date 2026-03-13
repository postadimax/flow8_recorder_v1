import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  List<FileSystemEntity> _sessions = [];
  String _selectedFileName = "Nessun file selezionato";
  bool _isPlaying = false;
  double _playPosition = 0.0;
  Timer? _timer;

  // Stato Mute per i 10 canali
  List<bool> _isMuted = List.generate(10, (index) => false);

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

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  // Legge i file e aggiorna la lista
  Future<void> _fetchSessions() async {
    final dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
    if (await dir.exists()) {
      final files = dir.listSync().where((f) => f.path.endsWith('.wav')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      setState(() => _sessions = files);
    }
  }

  // Elimina il file
  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      _fetchSessions(); // Rinfresca la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File eliminato"), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      debugPrint("Errore eliminazione: $e");
    }
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {
          _playPosition += 2.0;
          if (_playPosition > 2000) _stopAudio(); // Reset dopo un certo limite
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _stopAudio() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _playPosition = 0.0;
    });
  }

  // POP-UP ACCORDIAL PER I FILE
  void _showFileBrowser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("SESSIONI SALVATE", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final file = _sessions[index];
                    final name = file.path.split('/').last;
                    final stats = file.statSync();
                    final size = "${(stats.size / 1024 / 1024).toStringAsFixed(1)} MB";
                    final date = DateFormat('dd/MM HH:mm').format(stats.modified);

                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: const Color(0xFF00E5FF),
                        collapsedIconColor: Colors.white24,
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text("$date - $size", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                                onPressed: () {
                                  setState(() => _selectedFileName = name);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.file_open, size: 16, color: Colors.black),
                                label: const Text("CARICA", style: TextStyle(color: Colors.black)),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.8)),
                                onPressed: () async {
                                  await _deleteFile(file);
                                  setModalState(() {}); // Aggiorna il modal
                                },
                                icon: const Icon(Icons.delete_forever, size: 16),
                                label: const Text("ELIMINA"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_selectedFileName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        actions: [
          IconButton(icon: const Icon(Icons.folder_copy, color: Color(0xFF00E5FF)), onPressed: _showFileBrowser),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 10 CANALI MONO
                ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, i) => _buildTrackRow(i),
                ),
                // LINEA BIANCA (PLAYHEAD)
                Positioned(
                  left: 100 + _playPosition,
                  top: 0, bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),
              ],
            ),
          ),
          _buildTransportBar(),
        ],
      ),
    );
  }

  Widget _buildTrackRow(int i) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 100,
            color: const Color(0xFF0A0A0A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMuted[i] = !_isMuted[i]),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _isMuted[i] ? Colors.red : Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Text("M", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_channelInfo[i]['id']!, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(_channelInfo[i]['name']!, style: const TextStyle(color: Colors.grey, fontSize: 8)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: CustomPaint(
                painter: WavePainter(isMuted: _isMuted[i]),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: const Color(0xFF111111),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.first_page, color: Colors.white, size: 30), onPressed: _stopAudio),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: const Color(0xFF00E5FF), size: 55),
            onPressed: _togglePlay,
          ),
          IconButton(icon: const Icon(Icons.stop, color: Colors.white, size: 30), onPressed: _stopAudio),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final bool isMuted;
  WavePainter({required this.isMuted});

  @override
  void paint(Canvas canvas, Size size) {
    if (isMuted) return;
    final paint = Paint()..color = const Color(0xFF00E5FF).withOpacity(0.4)..strokeWidth = 1.5;
    double midY = size.height / 2;
    for (double i = 0; i < size.width; i += 6) {
      double h = 3 + (i % 50 < 25 ? 12 : 4);
      canvas.drawLine(Offset(i, midY - h), Offset(i, midY + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
