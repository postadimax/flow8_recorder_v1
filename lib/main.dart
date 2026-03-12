import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() => runApp(const MaterialApp(
      home: Flow8StudioUI(),
      debugShowCheckedModeBanner: false,
    ));

class Flow8StudioUI extends StatefulWidget {
  const Flow8StudioUI({super.key});

  @override
  State<Flow8StudioUI> createState() => _Flow8StudioUIState();
}

class _Flow8StudioUIState extends State<Flow8StudioUI> {
  bool isRecording = false;
  bool hasPermissions = false;
  String projectName = "FLOW_SESSION_01";
  String timerDisplay = "00:00:00";
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  // 1. Funzione per chiedere i permessi all'avvio o al click
  Future<void> checkAndRequestPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      hasPermissions = status.isGranted;
    });
    
    if (status.isGranted) {
      _showToast("Permessi attivati! Pronto per il FLOW 8.");
    } else {
      _showToast("Permesso negato. Controlla le impostazioni.");
    }
  }

  // 2. Funzione per generare il nome file (Progetto + Data + Ora)
  Future<String> getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return "${directory.path}/${projectName}_$timestamp.wav";
  }

  // 3. Logica del tasto REC
  void toggleRecording() async {
    if (!hasPermissions) {
      await checkAndRequestPermissions();
      return;
    }

    if (!isRecording) {
      // Inizio registrazione
      String path = await getRecordingPath();
      print("File salvato in: $path"); // Log di debug
      
      setState(() {
        isRecording = true;
        stopwatch.start();
      });
      
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          timerDisplay = _formatDuration(stopwatch.elapsed);
        });
      });

      _showToast("REC: ${path.split('/').last}");
    } else {
      // Stop registrazione
      setState(() {
        isRecording = false;
        stopwatch.stop();
        stopwatch.reset();
        timer?.cancel();
        timerDisplay = "00:00:00";
      });
      _showToast("Registrazione salvata.");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: Text("F8", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        title: const Text("FLOW 8 STUDIO", 
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        actions: [
          _buildStatusBadge(),
        ],
      ),
      body: Column(
        children: [
          _buildProjectHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) => _buildChannelTile(index),
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasPermissions ? Colors.cyanAccent : Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 14, color: hasPermissions ? Colors.cyanAccent : Colors.redAccent),
          const SizedBox(width: 4),
          Text(hasPermissions ? "READY" : "NO MIC", 
            style: TextStyle(fontSize: 9, color: hasPermissions ? Colors.cyanAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Text("PROGETTO", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Text(projectName, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.edit, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(int index) {
    final names = ["MIC 1", "MIC 2", "MIC 3", "MIC 4", "INST 5", "INST 6", "MAIN L", "MAIN R"];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text("${index + 1}", style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(names[index], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  child: FractionallySizedBox(
                    widthFactor: isRecording ? 0.3 + (index * 0.05) : 0, // Animazione se registra
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isRecording ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isRecording ? Colors.red : Colors.white10),
            ),
            child: Text(isRecording ? "REC" : "ARM", 
              style: TextStyle(color: isRecording ? Colors.red : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("REC TIME", style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text(timerDisplay, style: const TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.w200)),
            ],
          ),
          GestureDetector(
            onTap: toggleRecording,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: isRecording ? Colors.red : Colors.white10, width: 2),
                boxShadow: isRecording ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)] : [],
              ),
              child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record, 
                color: isRecording ? Colors.white : Colors.red, size: 40),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("STATUS", style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("STANDBY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
