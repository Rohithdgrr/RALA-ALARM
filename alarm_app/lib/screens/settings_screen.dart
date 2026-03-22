import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_settings.dart';
import '../services/ringtone_picker_service.dart';
import '../services/alarm_sound_service.dart';
import '../widgets/ui_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance', theme),
              _buildSettingsTile(
                context: context,
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: settings.isDarkMode ? 'On' : 'Off',
                trailing: Switch(
                  value: settings.isDarkMode,
                  activeColor: const Color(0xFF4A90D9),
                  onChanged: (value) => settings.setDarkMode(value),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Alarm Settings Section
              _buildSectionHeader('Alarm Settings', theme),
              
              // Alarm Duration
              _buildSettingsTile(
                context: context,
                icon: Icons.timer_outlined,
                title: 'Alarm Duration',
                subtitle: '${settings.alarmDurationMinutes} minutes',
                onTap: () => _showDurationPicker(context, settings),
              ),
              
              // Default Snooze
              _buildSettingsTile(
                context: context,
                icon: Icons.snooze_outlined,
                title: 'Default Snooze',
                subtitle: '${settings.defaultSnoozeMinutes} minutes',
                onTap: () => _showSnoozePicker(context, settings),
              ),
              
              const SizedBox(height: 24),
              
              // Sound & Display Section
              _buildSectionHeader('Sound & Display', theme),
              
              // Custom Ringtone
              _buildSettingsTile(
                context: context,
                icon: Icons.music_note_rounded,
                title: 'Custom Ringtone',
                subtitle: settings.ringtonePath.isEmpty 
                    ? 'Default' 
                    : settings.ringtonePath.split('/').last,
                trailing: settings.ringtonePath.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _previewRingtone(context, settings),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => settings.setRingtonePath(''),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    : null,
                onTap: () => _pickRingtone(context, settings),
              ),
              
              // Alarm Wallpaper
              _buildSettingsTile(
                context: context,
                icon: Icons.wallpaper_rounded,
                title: 'Alarm Wallpaper',
                subtitle: settings.wallpaperPath.isEmpty 
                    ? 'Default white' 
                    : settings.wallpaperPath.split('/').last,
                trailing: settings.wallpaperPath.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _previewWallpaper(context, settings),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => settings.setWallpaperPath(''),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    : null,
                onTap: () => _pickWallpaper(context, settings),
              ),
              
              // Show Wallpaper Preview
              if (settings.wallpaperPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4A90D9).withOpacity(0.3),
                                const Color(0xFF7B68EE).withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_rounded, size: 40, color: Colors.white54),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Wallpaper Preview',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader('About', theme),
              
              // Version
              _buildSettingsTile(
                context: context,
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              
              // Open Source Licenses
              _buildSettingsTile(
                context: context,
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
                subtitle: 'View third-party licenses',
                onTap: () => _showOpenSourceLicenses(context),
              ),
              
              // Terms & Conditions
              _buildSettingsTile(
                context: context,
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms of use',
                onTap: () => _showTermsAndConditions(context),
              ),
              
              // Privacy Policy
              _buildSettingsTile(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _showPrivacyPolicy(context),
              ),
              
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null)
                Icon(Icons.chevron_right_rounded, color: theme.iconTheme.color?.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, AppSettings settings) {
    final theme = Theme.of(context);
    final durations = [1, 3, 5, 10, 15, 30];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildPickerSheet(
        context: context,
        title: 'Alarm Duration',
        options: durations.map((d) => '$d min').toList(),
        selectedIndex: durations.indexOf(settings.alarmDurationMinutes),
        onSelect: (index) {
          settings.setAlarmDuration(durations[index]);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSnoozePicker(BuildContext context, AppSettings settings) {
    final theme = Theme.of(context);
    final snoozes = [5, 10, 15, 20, 30];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildPickerSheet(
        context: context,
        title: 'Default Snooze',
        options: snoozes.map((s) => '$s min').toList(),
        selectedIndex: snoozes.indexOf(settings.defaultSnoozeMinutes),
        onSelect: (index) {
          settings.setDefaultSnooze(snoozes[index]);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildPickerSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required int selectedIndex,
    required Function(int) onSelect,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(options.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelect(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4A90D9) 
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF4A90D9) 
                          : theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    options[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickRingtone(BuildContext context, AppSettings settings) async {
    // Use the new ringtone picker service with YouTube support
    final result = await RingtonePickerService.showRingtonePicker(context);
    
    if (result != null) {
      settings.setRingtonePath(result.path);
    }
  }

  Future<void> _pickWallpaper(BuildContext context, AppSettings settings) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        settings.setWallpaperPath(result.files.first.path ?? '');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image')),
        );
      }
    }
  }

  void _previewRingtone(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RingtonePreviewSheet(
        ringtonePath: settings.ringtonePath,
        audioPlayer: _audioPlayer,
      ),
    );
  }

  void _previewWallpaper(BuildContext context, AppSettings settings) {
    if (settings.wallpaperPath.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                Flexible(
                  child: Image.file(
                    File(settings.wallpaperPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(48),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 64,
                        ),
                      );
                    },
                  ),
                ),
                // Close button bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.wallpaperPath.split('/').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOpenSourceLicenses(BuildContext context) {
    final licenses = [
      {'name': 'Flutter', 'license': 'BSD 3-Clause License', 'url': 'flutter.dev'},
      {'name': 'Provider', 'license': 'MIT License', 'url': 'pub.dev/packages/provider'},
      {'name': 'audioplayers', 'license': 'MIT License', 'url': 'pub.dev/packages/audioplayers'},
      {'name': 'flutter_local_notifications', 'license': 'BSD 3-Clause License', 'url': 'pub.dev/packages/flutter_local_notifications'},
      {'name': 'shared_preferences', 'license': 'BSD 3-Clause License', 'url': 'pub.dev/packages/shared_preferences'},
      {'name': 'file_picker', 'license': 'MIT License', 'url': 'pub.dev/packages/file_picker'},
      {'name': 'google_fonts', 'license': 'Apache 2.0', 'url': 'pub.dev/packages/google_fonts'},
      {'name': 'uuid', 'license': 'MIT License', 'url': 'pub.dev/packages/uuid'},
      {'name': 'timezone', 'license': 'BSD 3-Clause License', 'url': 'pub.dev/packages/timezone'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Open Source Licenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app uses the following open source packages:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: licenses.length,
                    itemBuilder: (context, index) {
                      final license = licenses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    license['name']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    license['license']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade400),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTermsSection('1. Acceptance of Terms', 
                'By using this Alarm App, you agree to these Terms & Conditions. If you do not agree, please do not use the app.'),
              _buildTermsSection('2. Use of the App', 
                'This app is designed to help you wake up on time. You agree to use it responsibly and not rely solely on the app for critical alarms.'),
              _buildTermsSection('3. No Warranty', 
                'The app is provided "as is" without warranties. We are not responsible for missed alarms due to device issues, battery, or other technical problems.'),
              _buildTermsSection('4. Limitation of Liability', 
                'We shall not be liable for any indirect, incidental, special, or consequential damages arising from the use of this app.'),
              _buildTermsSection('5. Changes to Terms', 
                'We may update these terms at any time. Continued use of the app constitutes acceptance of the updated terms.'),
              _buildTermsSection('6. Contact', 
                'For questions about these terms, please contact us through the app store.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTermsSection('1. Data Collection', 
                'This app does not collect any personal data. All alarm settings are stored locally on your device only.'),
              _buildTermsSection('2. Local Storage', 
                'Your alarm times, labels, and preferences are saved to your device\'s local storage using SharedPreferences.'),
              _buildTermsSection('3. No Internet Required', 
                'The app works entirely offline. We do not send any data to external servers.'),
              _buildTermsSection('4. Permissions', 
                'The app requests permissions for notifications and audio playback solely for alarm functionality.'),
              _buildTermsSection('5. Third-Party Services', 
                'We do not use analytics, tracking, or advertising services.'),
              _buildTermsSection('6. Your Rights', 
                'You can delete all app data by uninstalling the application.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Ringtone Preview Sheet Widget
class _RingtonePreviewSheet extends StatefulWidget {
  final String ringtonePath;
  final AudioPlayer audioPlayer;

  const _RingtonePreviewSheet({
    required this.ringtonePath,
    required this.audioPlayer,
  });

  @override
  State<_RingtonePreviewSheet> createState() => _RingtonePreviewSheetState();
}

class _RingtonePreviewSheetState extends State<_RingtonePreviewSheet> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Listen to player state changes
    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration changes
    widget.audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    widget.audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to player completion
    widget.audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      try {
        // Check if it's a URL (YouTube or other)
        if (widget.ringtonePath.startsWith('http')) {
          if (widget.ringtonePath.contains('youtube.com') || widget.ringtonePath.contains('youtu.be')) {
            // YouTube URL - need to download first via AlarmSoundService
            final soundService = AlarmSoundService();
            await soundService.playPreview(widget.ringtonePath);
          } else {
            // Direct URL
            await widget.audioPlayer.play(UrlSource(widget.ringtonePath));
          }
        } 
        // Check if it's an asset ringtone
        else if (AlarmSoundService.assetRingtones.containsKey(widget.ringtonePath)) {
          final assetPath = AlarmSoundService.assetRingtones[widget.ringtonePath]!['asset'] as String;
          await widget.audioPlayer.play(AssetSource(assetPath.replaceFirst('assets/', '')));
        }
        // Check if it's an in-app ringtone
        else if (AlarmSoundService.inAppRingtones.containsKey(widget.ringtonePath)) {
          // Generate and play WAV from frequencies
          final soundService = AlarmSoundService();
          await soundService.playPreview(widget.ringtonePath);
        }
        // Check if it's a local file (has path separators)
        else if (widget.ringtonePath.contains('/') || widget.ringtonePath.contains('\\')) {
          await widget.audioPlayer.play(DeviceFileSource(widget.ringtonePath));
        } else {
          // Fallback: try playing as an in-app ringtone
          final soundService = AlarmSoundService();
          await soundService.playPreview(widget.ringtonePath);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing audio: $e')),
          );
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.ringtonePath.split('/').last;
    final isYouTube = widget.ringtonePath.startsWith('http');

    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90D9).withOpacity(0.3),
                  const Color(0xFF7B68EE).withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isYouTube ? Icons.video_library_rounded : Icons.music_note_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Ringtone Preview',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // File name
          Text(
            fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          
          // Progress bar
          if (_duration > Duration.zero)
            Column(
              children: [
                Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble(),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                  onChanged: (value) async {
                    final position = Duration(milliseconds: value.toInt());
                    await widget.audioPlayer.seek(position);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPlaying 
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                      : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isPlaying ? const Color(0xFFFF6B6B) : Colors.white).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                  key: ValueKey(_isPlaying),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Close button
          GradientButton(
            text: 'Close',
            width: double.infinity,
            height: 48,
            borderRadius: 12,
            gradientColors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.1)],
            onPressed: () async {
              await widget.audioPlayer.stop();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
