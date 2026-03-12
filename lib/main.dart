import 'package:flutter/material.dart';
import 'package:record/record.dart'; // Importa il plugin audio
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
  final AudioRecorder audioRecorder = AudioRecorder(); // Istanza del registratore
  bool isRecording = false;
  String timerDisplay = "00:00:00";
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  @override
  void dispose() {
    audioRecorder.dispose(); // Pulizia memoria
    super.dispose();
  }

  // Chiedi i permessi e avvia/ferma
  void toggleRecording() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    try {
      // 1. Controlla permessi
      if (await Permission.microphone.request().isGranted) {
        
        // 2. Prepara il percorso file
        final directory = await getApplicationDocumentsDirectory();
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String path = "${directory.path}/FLOW_SESSION_$timestamp.wav";

        // 3. Configura per FLOW 8 (10 canali, 48kHz, WAV)
        const config = RecordConfig(
          encoder: AudioEncoder.wav, // Formato non compresso professionale
          sampleRate: 48000,         // Frequenza di campionamento standard FLOW 8
          numChannels: 10,           // <--- QUI ABILITIAMO I 10 CANALI USB
        );

        // 4. Via!
        await audioRecorder.start(config, path: path);

        setState(() {
          isRecording = true;
          stopwatch.start();
        });

        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => timerDisplay = _formatDuration(stopwatch.elapsed));
        });

        _showToast("Registrazione avviata su 10 canali");
      }
    } catch (e) {
      _showToast("Errore: $e");
    }
  }

  Future<void> stopRecording() async {
    final path = await audioRecorder.stop();
    setState(() {
      isRecording = false;
      stopwatch.stop();
      stopwatch.reset();
      timer?.cancel();
      timerDisplay = "00:00:00";
    });
    _showToast("Salvato: ${path?.split('/').last}");
  }

  // --- Funzioni di supporto Grafico (Uguali a prima) ---
  String _formatDuration(Duration d) => 
      "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  void _showToast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    // Qui tieni l'estetica "Studio" che abbiamo costruito nell'ultimo step
    // Assicurati che il tasto REC chiami toggleRecording
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A), title: const Text("FLOW 8 STUDIO PRO")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(timerDisplay, style: const TextStyle(color: Colors.cyanAccent, fontSize: 48, fontWeight: FontWeight.w200)),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: toggleRecording,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isRecording ? Colors.red : Colors.grey[900],
                child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(isRecording ? "REGISTRAZIONE IN CORSO..." : "PRONTO A REGISTRARE", style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
