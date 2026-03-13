import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  List<FileSystemEntity> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  // Legge i file dalla cartella dedicata
  Future<void> _fetchSessions() async {
    try {
      final dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
      if (await dir.exists()) {
        final files = dir.listSync().where((f) => f.path.endsWith('.wav')).toList();
        // Ordina i file dal più recente al più vecchio
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        setState(() {
          _sessions = files;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Errore lettura file: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("SESSIONI REGISTRATE", style: TextStyle(fontSize: 14, color: Color(0xFF00E5FF))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : _sessions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) => _buildFileCard(_sessions[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 60, color: Colors.white12),
          SizedBox(height: 10),
          Text("Nessuna traccia trovata", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildFileCard(FileSystemEntity file) {
    String fileName = file.path.split('/').last;
    FileStat stats = file.statSync();
    String date = DateFormat('dd/MM/yyyy HH:mm').format(stats.modified);
    String size = "${(stats.size / (1024 * 1024)).toStringAsFixed(1)} MB";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: const Icon(Icons.multitrack_audio, color: Color(0xFF00E5FF)),
        title: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("$date  •  $size", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        trailing: const Icon(Icons.tune, color: Colors.white38),
        onTap: () => _openMixer(context, fileName),
      ),
    );
  }

  void _openMixer(BuildContext context, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fileName, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 8,
                itemBuilder: (context, index) => _buildMiniFader(index + 1),
              ),
            ),
            _buildPlayControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFader(int ch) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("CH $ch", style: const TextStyle(color: Colors.grey, fontSize: 10)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(value: 0.8, onChanged: (v) {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayControl() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.skip_previous, color: Colors.white, size: 30),
          const SizedBox(width: 30),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF00E5FF),
            child: Icon(Icons.play_arrow, color: Colors.black, size: 35),
          ),
          const SizedBox(width: 30),
          const Icon(Icons.skip_next, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}
