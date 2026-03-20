import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/alarm_sound_service.dart';

enum RingtoneSource {
  local,
  youtube,
  inApp,
}

class RingtonePickerService {
  static final AlarmSoundService _soundService = AlarmSoundService();

  static Future<RingtoneResult?> showRingtonePicker(BuildContext context) async {
    return showModalBottomSheet<RingtoneResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RingtonePickerSheet(),
    );
  }

  static Future<void> previewRingtone(String name) async {
    await _soundService.playPreview(name);
  }

  static Future<void> stopPreview() async {
    await _soundService.stop();
  }
}

class RingtoneResult {
  final String path;
  final String name;
  final RingtoneSource source;

  RingtoneResult({
    required this.path,
    required this.name,
    required this.source,
  });
}

class _RingtonePickerSheet extends StatefulWidget {
  const _RingtonePickerSheet();

  @override
  State<_RingtonePickerSheet> createState() => _RingtonePickerSheetState();
}

class _RingtonePickerSheetState extends State<_RingtonePickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _youtubeController = TextEditingController();
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String? _selectedLocalPath;
  String? _currentlyPreviewing;
  final AlarmSoundService _soundService = AlarmSoundService();

  // Map icon names to IconData for in-app ringtones
  static const Map<String, IconData> _iconMap = {
    'music_note': Icons.music_note_rounded,
    'wb_sunny': Icons.wb_sunny_rounded,
    'timer': Icons.timer_rounded,
    'notifications': Icons.notifications_rounded,
    'alarm': Icons.alarm_rounded,
    'waves': Icons.waves_rounded,
    'forest': Icons.forest_rounded,
    'piano': Icons.piano_rounded,
    'wb_twilight': Icons.wb_twilight_rounded,
    'spa': Icons.spa_rounded,
    'graphic_eq': Icons.graphic_eq_rounded,
    'audiotrack': Icons.audiotrack_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeController.dispose();
    _soundService.stop();
    super.dispose();
  }

  Future<void> _pickLocalAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedLocalPath = result.files.first.path;
        });
        // Preview the selected file
        if (_selectedLocalPath != null) {
          _previewSound(_selectedLocalPath!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not pick audio file'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _addYoutubeUrl() async {
    final url = _youtubeController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a YouTube URL'),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid YouTube URL'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
    });
    
    try {
      String? resultPath;
      
      // Show real-time progress with caching check
      resultPath = await _soundService.getOrDownloadYoutubeAudio(
        url,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );
      
      if (mounted && resultPath != null) {
        _soundService.stop();
        setState(() {
          _isLoading = false;
          _downloadProgress = 1.0;
        });
        
        Navigator.pop(
          context,
          RingtoneResult(
            path: resultPath,
            name: 'YouTube Audio',
            source: RingtoneSource.youtube,
          ),
        );
      }
    } catch (e) {
      debugPrint('YouTube download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _isLoading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _previewSound(String name) async {
    if (_currentlyPreviewing == name) {
      // Stop if already previewing this sound
      await _soundService.stop();
      setState(() => _currentlyPreviewing = null);
      return;
    }

    setState(() => _currentlyPreviewing = name);
    await _soundService.playPreview(name);

    // Auto-stop after preview
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentlyPreviewing == name) {
        setState(() => _currentlyPreviewing = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Ringtone',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: subtitleColor,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('In-App'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Local'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('YouTube'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInAppRingtones(textColor, subtitleColor, cardColor),
                _buildLocalFiles(textColor, subtitleColor, cardColor),
                _buildYoutubeInput(textColor, subtitleColor, cardColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppRingtones(Color textColor, Color subtitleColor, Color cardColor) {
    final ringtoneNames = AlarmSoundService.allInAppRingtoneNames;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ringtoneNames.length,
      itemBuilder: (context, index) {
        final name = ringtoneNames[index];
        final ringtone = AlarmSoundService.inAppRingtones[name]!;
        final iconName = ringtone['icon'] as String;
        final description = ringtone['description'] as String;
        final icon = _iconMap[iconName] ?? Icons.music_note;
        final isPreviewing = _currentlyPreviewing == name;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isPreviewing
                ? const Color(0xFF4A90D9).withOpacity(0.12)
                : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isPreviewing
                ? Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isPreviewing
                    ? const LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF4A90D9).withOpacity(0.15),
                          const Color(0xFF7B68EE).withOpacity(0.15),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isPreviewing ? Colors.white : const Color(0xFF4A90D9),
                size: 22,
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview button
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isPreviewing
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_rounded,
                      key: ValueKey(isPreviewing),
                      color: const Color(0xFF4A90D9),
                      size: 28,
                    ),
                  ),
                  onPressed: () => _previewSound(name),
                ),
              ],
            ),
            onTap: () {
              _soundService.stop();
              Navigator.pop(
                context,
                RingtoneResult(
                  path: name,
                  name: name,
                  source: RingtoneSource.inApp,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocalFiles(Color textColor, Color subtitleColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pick file button
          GestureDetector(
            onTap: _pickLocalAudio,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A90D9).withOpacity(0.08),
                    const Color(0xFF7B68EE).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A90D9).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Browse Audio Files',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select MP3, WAV, OGG, or M4A from your device',
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_selectedLocalPath != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.audio_file_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLocalPath!.split('/').last.split('\\').last,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap "Select" to use this ringtone',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Preview
                  IconButton(
                    icon: Icon(
                      _currentlyPreviewing == _selectedLocalPath
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_rounded,
                      color: const Color(0xFF4A90D9),
                    ),
                    onPressed: () => _previewSound(_selectedLocalPath!),
                  ),
                  // Select button
                  Container(
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
                          final fileName = _selectedLocalPath!.split('/').last.split('\\').last;
                          Navigator.pop(
                            context,
                            RingtoneResult(
                              path: _selectedLocalPath!,
                              name: fileName,
                              source: RingtoneSource.local,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Select',
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYoutubeInput(Color textColor, Color subtitleColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF0000).withOpacity(0.08),
                  const Color(0xFFFF6B6B).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF0000).withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: Color(0xFFFF0000), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YouTube Audio',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paste a YouTube link to use as your alarm sound. Works best with short videos.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'YouTube URL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _youtubeController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                hintStyle: TextStyle(color: subtitleColor),
                prefixIcon: Icon(Icons.link_rounded, color: subtitleColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick suggestions
          Text(
            'Quick Suggestions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 10),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('🔔 Alarm sounds', cardColor, textColor),
              _buildSuggestionChip('🌿 Nature sounds', cardColor, textColor),
              _buildSuggestionChip('🎵 Relaxing music', cardColor, textColor),
              _buildSuggestionChip('🎶 Pop ringtones', cardColor, textColor),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Add button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isLoading ? null : _addYoutubeUrl,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [const Color(0xFFFF0000), const Color(0xFFFF4444)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(
                        color: const Color(0xFFFF0000).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              value: _downloadProgress > 0 ? _downloadProgress : null,
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _downloadProgress > 0 
                                ? '${(_downloadProgress * 100).toInt()}%'
                                : 'Processing...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add YouTube Ringtone',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, Color bgColor, Color textColor) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search YouTube for: ${label.substring(2).trim()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
