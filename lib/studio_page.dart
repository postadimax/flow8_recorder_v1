class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  List<FileSystemEntity> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  // Scansiona la cartella Flow8Sessions per trovare i file .wav
  Future<void> _fetchSessions() async {
    try {
      final dir = Directory('/storage/emulated/0/Documents/Flow8Sessions');
      if (await dir.exists()) {
        final files = dir.listSync().where((f) => f.path.endsWith('.wav')).toList();
        // Ordina per data (più recenti in alto)
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        setState(() {
          _sessions = files;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("STUDIO - MULTITRACK", style: TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : _sessions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text("NESSUNA REGISTRAZIONE", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(FileSystemEntity file) {
    String fileName = file.path.split('/').last;
    var stats = file.statSync();
    String date = DateFormat('dd MMM yyyy - HH:mm').format(stats.modified);
    String size = "${(stats.size / 1024 / 1024).toStringAsFixed(1)} MB";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text("$date  •  $size", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ),
        trailing: const Icon(Icons.tune, color: Color(0xFF00E5FF)),
        onTap: () => _showMixerPanel(context, fileName),
      ),
    );
  }

  // IL MIXER DI SCOMPOSIZIONE
  void _showMixerPanel(BuildContext context, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header del Mixer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SESSION MIXER", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(fileName, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Griglia degli 8 Canali
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 8,
                itemBuilder: (context, index) => _buildTrackControl(index + 1),
              ),
            ),
            
            // Barra di trasporto (Play/Stop/Export)
            _buildTransportBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackControl(int ch) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CH $ch", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Icon(Icons.volume_up, size: 12, color: Colors.grey),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: 0.7,
              activeColor: const Color(0xFF00E5FF),
              inactiveColor: Colors.white10,
              onChanged: (v) {},
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniButton("MUTE", Colors.red),
              _miniButton("SOLO", Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTransportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _transportIcon(Icons.skip_previous),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 20),
          _transportIcon(Icons.skip_next),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
            onPressed: () {},
            icon: const Icon(Icons.ios_share, size: 16),
            label: const Text("EXPORT", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _transportIcon(IconData icon) {
    return Icon(icon, color: Colors.white, size: 28);
  }
}
