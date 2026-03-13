import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

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

class _Flow8StudioState extends State<Flow8Studio> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
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
              // --- HEADER ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // CORRETTO: FontWeight.w900 invece di .black
                    child: const Text("F8", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("FLOW 8 STUDIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 16),
                        Text(" USB LINK ACTIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- PROJECT BAR ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: "PROGETTO   ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      TextSpan(text: "FLOW_SESSION", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("INPUT MONITOR", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ),

              // --- CHANNEL LIST ---
              Expanded(
                child: ListView(
                  children: [
                    _buildChannelRow(1, "MIC/LINE 1", true),
                    _buildChannelRow(2, "MIC/LINE 2", false),
                    _buildChannelRow(3, "MIC/LINE 3", false),
                    _buildChannelRow(4, "MIC/LINE 4", false),
                    _buildChannelRow(5, "INST 5", false),
                    _buildChannelRow(6, "INST 6", false),
                  ],
                ),
              ),

              // --- FOOTER ---
              Row(
                children: [
                  _buildFooterStat("DATA", "0.0M"),
                  const SizedBox(width: 24),
                  _buildFooterStat("DISK", "42G"),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _isRecording = !_isRecording),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2E1515),
                        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            color: _isRecording ? Colors.red : const Color(0xFF441111)
                          ),
                        ),
                      ),
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

  Widget _buildFooterStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChannelRow(int id, String label, bool isRecording) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CH", style: TextStyle(color: Colors.grey, fontSize: 8)),
                Text("$id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(20, (index) {
                    return Expanded(
                      child: Container(
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: index < (isRecording ? 12 : 0) ? const Color(0xFF00E676) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : const Color(0xFF222222),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(isRecording ? "REC" : "ARM", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
