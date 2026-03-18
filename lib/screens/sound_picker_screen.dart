import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/alarm_sound_service.dart';

class SoundPickerScreen extends StatefulWidget {
  final String currentSound;

  const SoundPickerScreen({super.key, required this.currentSound});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedSound;
  String? _currentlyPreviewing;
  final AlarmSoundService _soundService = AlarmSoundService();
  late TabController _tabController;
  final TextEditingController _youtubeController = TextEditingController();
  String? _localFilePath;

  static const Map<String, IconData> _iconMap = {
    'music_note': Icons.music_note_rounded,
    'graphic_eq': Icons.graphic_eq_rounded,
    'schedule': Icons.schedule_rounded,
    'alarm': Icons.alarm_rounded,
    'public': Icons.public_rounded,
    'notifications': Icons.notifications_rounded,
    'phone': Icons.phone_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _soundService.stop();
    _tabController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String name) async {
    if (_currentlyPreviewing == name) {
      await _soundService.stop();
      setState(() => _currentlyPreviewing = null);
      return;
    }

    setState(() => _currentlyPreviewing = name);
    await _soundService.playPreview(name);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentlyPreviewing == name) {
        setState(() => _currentlyPreviewing = null);
      }
    });
  }

  Future<void> _pickLocalFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _localFilePath = result.files.single.path;
        _selectedSound = _localFilePath!;
      });
      await _soundService.stop();
      await _soundService.playPreview(_localFilePath!);
    }
  }

  void _addYoutubeLink() {
    final url = _youtubeController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _selectedSound = url;
      });
      _soundService.playPreview(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('YouTube link added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: subtitleColor),
          onPressed: () {
            _soundService.stop();
            Navigator.pop(context, _selectedSound);
          },
        ),
        title: Text(
          'Choose Ringtone',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          if (_selectedSound != widget.currentSound)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _soundService.stop();
                    Navigator.pop(context, _selectedSound);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A90D9),
          unselectedLabelColor: subtitleColor,
          indicatorColor: const Color(0xFF4A90D9),
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'In-App'),
            Tab(icon: Icon(Icons.folder), text: 'Local'),
            Tab(icon: Icon(Icons.link), text: 'YouTube'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssetRingtonesList(isDark, textColor, subtitleColor),
          _buildLocalPicker(isDark, textColor, subtitleColor),
          _buildYoutubeInput(isDark, textColor, subtitleColor),
        ],
      ),
    );
  }

  Widget _buildAssetRingtonesList(bool isDark, Color textColor, Color subtitleColor) {
    final assetRingtoneNames = AlarmSoundService.allAssetRingtoneNames;

    if (assetRingtoneNames.isEmpty) {
      return Center(
        child: Text(
          'No ringtones available',
          style: TextStyle(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: assetRingtoneNames.length,
      itemBuilder: (context, index) {
        final name = assetRingtoneNames[index];
        final ringtone = AlarmSoundService.assetRingtones[name]!;
        final iconName = ringtone['icon'] as String;
        final description = ringtone['description'] as String;
        final icon = _iconMap[iconName] ?? Icons.music_note;
        final isSelected = name == _selectedSound;
        final isPreviewing = _currentlyPreviewing == name;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4A90D9).withOpacity(isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3))
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : subtitleColor,
                size: 22,
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? const Color(0xFF4A90D9) : textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isPreviewing
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    color: const Color(0xFF4A90D9),
                    size: 26,
                  ),
                  onPressed: () => _previewSound(name),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
            onTap: () {
              setState(() => _selectedSound = name);
            },
          ),
        );
      },
    );
  }

  Widget _buildLocalPicker(bool isDark, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Audio File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an MP3, WAV, or other audio file from your device',
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickLocalFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: const Color(0xFF4A90D9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Browse Files',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select audio file',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_localFilePath != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audio_file, color: Color(0xFF4A90D9)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _localFilePath!.split('/').last.split('\\').last,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedSound == _localFilePath)
                    const Icon(Icons.check_circle, color: Color(0xFF4A90D9)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYoutubeInput(bool isDark, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YouTube URL',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a YouTube video URL to use as alarm sound',
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _youtubeController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'https://youtube.com/watch?v=...',
              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.link, color: Color(0xFF4A90D9)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A90D9)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addYoutubeLink,
              icon: const Icon(Icons.add),
              label: const Text('Add YouTube Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
