import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      home: Flow8StudioUI(),
      debugShowCheckedModeBanner: false,
    ));

class Flow8StudioUI extends StatelessWidget {
  const Flow8StudioUI({super.key});

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
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, size: 14, color: Colors.cyanAccent),
          SizedBox(width: 4),
          Text("USB LINK ACTIVE", style: TextStyle(fontSize: 9, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
        child: const Row(
          children: [
            Text("PROGETTO", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(width: 20),
            Text("FLOW_SESSION_01", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(Icons.edit, color: Colors.white24, size: 18),
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
                // Vu-Meter simulato
                Container(
                  height: 10,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
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
          // Pulsante ARM (Solo estetica)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: const Text("ARM", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("TIME", style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("00:00:00", style: TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.w200)),
            ],
          ),
          // Tasto REC
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 40),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("DISK", style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("42 GB", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}